package pt.taxy.app.dm3irs

import android.content.Context
import android.security.KeyChain
import android.util.Base64
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.net.Socket
import java.net.URL
import java.security.KeyStore
import java.security.Principal
import java.security.PrivateKey
import java.security.cert.X509Certificate
import java.time.Instant
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.KeyManager
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLEngine
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509ExtendedKeyManager
import javax.xml.parsers.DocumentBuilderFactory
import org.w3c.dom.Element
import org.w3c.dom.Node
import pt.taxy.app.efatura.CipherCertificateStore
import pt.taxy.app.efatura.FactIntWsProtocol
import pt.taxy.app.efatura.RuntimeBridgeException
import pt.taxy.app.efatura.SecureCredentialStore

internal class Dm3IrsNativeClient(
    private val context: Context,
    private val credentials: SecureCredentialStore,
    private val cipherCertificates: CipherCertificateStore,
    private val alias: () -> String?,
) {
    fun history2024(): Map<String, Any?> {
        val stored = credentials.load() ?: throw failure("NOT_CONFIGURED", "Liga primeiro ao Portal das Finanças.")
        try {
            val identity = loadIdentity(alias() ?: throw failure("NOT_CONFIGURED", "Seleciona a identidade Taxy do dispositivo."))
            val check = execute(
                Dm3IrsReadOperation.CHECK_DELIVERY,
                stored.nif,
                stored.password,
                Dm3IrsProtocol.checkDeliveryBody(2024, baseNif(stored.nif)),
                identity,
            )
            val declarationId = check.optional("declaracao")
            if (declarationId == null || !Regex("^[1-9]\\d{0,30}$").matches(declarationId)) {
                return mapOf("available" to false)
            }
            val receipt = execute(
                Dm3IrsReadOperation.GET_RECEIPT,
                stored.nif,
                stored.password,
                Dm3IrsProtocol.receiptBody(declarationId, baseNif(stored.nif)),
                identity,
            )
            val receiptId = receipt.required("declaracao")
            val nifA = receipt.required("nifA")
            val nifB = receipt.optional("nifB")
            if (receiptId != declarationId || !Regex("^\\d{9}$").matches(nifA) ||
                (nifB != null && !Regex("^\\d{9}$").matches(nifB))) {
                throw failure("INVALID_DOCUMENT", "A declaração devolvida não pôde ser validada.")
            }
            val declaration = execute(
                Dm3IrsReadOperation.GET_DECLARATION,
                stored.nif,
                stored.password,
                Dm3IrsProtocol.declarationBody(receiptId, nifA, nifB),
                identity,
                maximumBytes = MAX_DECLARATION_RESPONSE_BYTES,
            )
            val encoded = declaration.required("pdf").replace(Regex("\\s+"), "")
            if (!Regex("^[A-Za-z0-9+/]*={0,2}$").matches(encoded)) {
                throw failure("INVALID_DOCUMENT", "A declaração devolvida não pôde ser validada.")
            }
            val pdf = try {
                Base64.decode(encoded, Base64.DEFAULT)
            } catch (_: IllegalArgumentException) {
                throw failure("INVALID_DOCUMENT", "A declaração devolvida não pôde ser validada.")
            }
            return try {
                Dm3IrsPdfMemoryExtractor.extract(pdf).toMap()
            } catch (_: UnknownDm3IrsTemplate) {
                throw failure("UNKNOWN_TEMPLATE", "O formato desta declaração ainda não é reconhecido com segurança.")
            } catch (_: InvalidDm3IrsDocument) {
                throw failure("INVALID_DOCUMENT", "A declaração devolvida não pôde ser validada.")
            } finally {
                pdf.fill(0)
            }
        } finally {
            stored.clear()
        }
    }

    private fun execute(
        operation: Dm3IrsReadOperation,
        username: String,
        password: CharArray,
        body: String,
        identity: ClientIdentity,
        maximumBytes: Int = MAX_RESPONSE_BYTES,
    ): SoapPayload {
        check(operation.wireName in Dm3IrsProtocol.allowedOperations)
        val created = FactIntWsProtocol.created(Instant.now())
        val security = FactIntWsProtocol.securityMaterial(password, created, cipherCertificates.load().publicKey)
        val envelope = Dm3IrsProtocol.envelope(operation, username, security, body)
        val response = transport(operation, envelope, identity, maximumBytes)
        return parse(response, operation)
    }

    private fun transport(
        operation: Dm3IrsReadOperation,
        xml: String,
        identity: ClientIdentity,
        maximumBytes: Int,
    ): ByteArray {
        val trustFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
        trustFactory.init(null as KeyStore?)
        val ssl = SSLContext.getInstance("TLS")
        ssl.init(arrayOf<KeyManager>(SingleIdentityKeyManager(identity)), trustFactory.trustManagers, null)
        val connection = URL(Dm3IrsProtocol.ENDPOINT).openConnection() as HttpsURLConnection
        try {
            connection.sslSocketFactory = ssl.socketFactory
            connection.requestMethod = "POST"
            connection.instanceFollowRedirects = false
            connection.connectTimeout = 20_000
            connection.readTimeout = 90_000
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "text/xml")
            connection.setRequestProperty("SOAPAction", Dm3IrsProtocol.soapAction(operation))
            connection.setRequestProperty("Cache-Control", "no-store")
            connection.outputStream.use { it.write(xml.toByteArray(Charsets.UTF_8)) }
            if (connection.responseCode != 200) {
                throw failure("SERVICE_UNAVAILABLE", "O serviço de IRS anterior está temporariamente indisponível.")
            }
            val output = ByteArrayOutputStream(minOf(maximumBytes, 256 * 1024))
            connection.inputStream.use { input ->
                val buffer = ByteArray(64 * 1024)
                while (true) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    if (output.size() + read > maximumBytes) {
                        throw failure("INVALID_DOCUMENT", "A resposta recebida ultrapassa o limite seguro.")
                    }
                    output.write(buffer, 0, read)
                }
            }
            return output.toByteArray()
        } catch (error: RuntimeBridgeException) {
            throw error
        } catch (error: Exception) {
            throw failure("NETWORK_ERROR", "Não foi possível consultar o IRS anterior.", error)
        } finally {
            connection.disconnect()
        }
    }

    private fun parse(bytes: ByteArray, operation: Dm3IrsReadOperation): SoapPayload {
        try {
            val factory = DocumentBuilderFactory.newInstance().apply {
                isNamespaceAware = true
                setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)
                setFeature("http://xml.org/sax/features/external-general-entities", false)
                setFeature("http://xml.org/sax/features/external-parameter-entities", false)
                setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false)
                isXIncludeAware = false
                isExpandEntityReferences = false
            }
            val document = factory.newDocumentBuilder().parse(ByteArrayInputStream(bytes))
            val fault = first(document.documentElement, "Fault")
            if (fault != null) throw failure("SERVICE_UNAVAILABLE", "O serviço de IRS anterior devolveu um erro.")
            val root = first(document.documentElement, operation.responseRoot)
                ?: throw failure("INVALID_DOCUMENT", "A resposta do IRS anterior não foi reconhecida.")
            val status = text(root, "codigo") ?: text(root, "EstadoOperacao") ?: text(root, "estadoOperacao")
            if (status != "0") {
                val code = if (status == "130" || status == "131") "NO_DECLARATION" else "SERVICE_UNAVAILABLE"
                throw failure(code, if (code == "NO_DECLARATION") "Não existe uma declaração anterior disponível." else "O serviço de IRS anterior não concluiu a consulta.")
            }
            return SoapPayload(root)
        } finally {
            bytes.fill(0)
        }
    }

    private fun loadIdentity(alias: String): ClientIdentity {
        val key = KeyChain.getPrivateKey(context, alias)
            ?: throw failure("NOT_CONFIGURED", "A identidade selecionada já não está disponível.")
        val chain = KeyChain.getCertificateChain(context, alias)
        if (chain.isNullOrEmpty()) throw failure("NOT_CONFIGURED", "A cadeia da identidade está indisponível.")
        return ClientIdentity(alias, key, chain)
    }

    private fun baseNif(username: String): String = Regex("^(\\d{9})").find(username)?.groupValues?.get(1)
        ?: throw failure("AUTH_ERROR", "A identidade do Portal das Finanças não é válida.")

    private fun first(root: Element, localName: String): Element? {
        val nodes = root.getElementsByTagNameNS("*", localName)
        return if (nodes.length == 0) null else nodes.item(0) as? Element
    }

    private fun text(root: Element, localName: String): String? = first(root, localName)
        ?.textContent?.trim()?.takeIf { it.isNotEmpty() }

    private inner class SoapPayload(private val root: Element) {
        fun optional(name: String): String? = text(root, name)
        fun required(name: String): String = optional(name)
            ?: throw failure("INVALID_DOCUMENT", "A resposta do IRS anterior está incompleta.")
    }

    private data class ClientIdentity(
        val alias: String,
        val privateKey: PrivateKey,
        val chain: Array<X509Certificate>,
    )

    private class SingleIdentityKeyManager(private val identity: ClientIdentity) : X509ExtendedKeyManager() {
        override fun chooseClientAlias(keyType: Array<out String>?, issuers: Array<out Principal>?, socket: Socket?): String = identity.alias
        override fun chooseEngineClientAlias(keyType: Array<out String>?, issuers: Array<out Principal>?, engine: SSLEngine?): String = identity.alias
        override fun getCertificateChain(alias: String?): Array<X509Certificate>? = if (alias == identity.alias) identity.chain else null
        override fun getPrivateKey(alias: String?): PrivateKey? = if (alias == identity.alias) identity.privateKey else null
        override fun getClientAliases(keyType: String?, issuers: Array<out Principal>?): Array<String> = arrayOf(identity.alias)
        override fun chooseServerAlias(keyType: String?, issuers: Array<out Principal>?, socket: Socket?): String? = null
        override fun getServerAliases(keyType: String?, issuers: Array<out Principal>?): Array<String>? = null
    }

    private fun failure(code: String, message: String, cause: Throwable? = null) = RuntimeBridgeException(code, message, cause)

    private companion object {
        const val MAX_RESPONSE_BYTES = 2 * 1024 * 1024
        const val MAX_DECLARATION_RESPONSE_BYTES = 28 * 1024 * 1024
    }
}
