package pt.taxy.app.efatura

import android.content.Context
import android.os.Build
import android.security.KeyChain
import java.io.ByteArrayInputStream
import java.io.File
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.Socket
import java.net.URL
import java.security.KeyStore
import java.security.Principal
import java.security.PrivateKey
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.time.Year
import java.time.ZoneOffset
import java.util.zip.GZIPInputStream
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.KeyManager
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLEngine
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509ExtendedKeyManager
import javax.xml.parsers.DocumentBuilderFactory
import org.w3c.dom.Element
import org.w3c.dom.Node

internal class RuntimeBridgeException(
    val code: String,
    val safeMessage: String,
    cause: Throwable? = null,
) : Exception(safeMessage, cause)

internal class CipherCertificateStore(private val context: Context) {
    private val file: File get() = File(context.noBackupFilesDir, FILE_NAME)

    fun hasCertificate(): Boolean = file.isFile && runCatching { load() }.isSuccess

    fun save(bytes: ByteArray) {
        val certificate = parse(bytes)
        if (certificate.publicKey.algorithm != "RSA") {
            throw RuntimeBridgeException(
                "RUNTIME_NOT_CONFIGURED",
                "A chave pública selecionada não é compatível com o serviço.",
            )
        }
        val temporary = File(context.noBackupFilesDir, "$FILE_NAME.tmp")
        temporary.writeBytes(certificate.encoded)
        if (file.exists()) file.delete()
        if (!temporary.renameTo(file)) {
            temporary.delete()
            throw RuntimeBridgeException(
                "RUNTIME_NOT_CONFIGURED",
                "Não foi possível guardar a chave pública selecionada.",
            )
        }
    }

    fun load(): X509Certificate = parse(file.readBytes())

    private fun parse(bytes: ByteArray): X509Certificate = try {
        CertificateFactory.getInstance("X.509")
            .generateCertificate(ByteArrayInputStream(bytes)) as X509Certificate
    } catch (error: Exception) {
        throw RuntimeBridgeException(
            "RUNTIME_NOT_CONFIGURED",
            "A chave pública selecionada não é um certificado X.509 válido.",
            error,
        )
    }

    private companion object {
        const val FILE_NAME = "at_factintws_cipher.cer"
    }
}

internal class FactIntWsNativeClient(
    private val context: Context,
    private val credentials: SecureCredentialStore,
    private val cipherCertificates: CipherCertificateStore,
    private val alias: () -> String?,
    private val ntp: NtpTimeProvider = NtpTimeProvider(),
) {
    fun overview(): Map<String, Any?> = execute(FactIntOperation.OVERVIEW)

    fun pendingInvoices(): Map<String, Any?> = execute(FactIntOperation.PENDING)

    fun sectorInvoices(sectorCode: String): Map<String, Any?> =
        execute(FactIntOperation.SECTOR, sectorCode)

    private fun execute(
        operation: FactIntOperation,
        sectorCode: String? = null,
    ): Map<String, Any?> {
        val stored = credentials.load() ?: throw RuntimeBridgeException(
            "RUNTIME_NOT_CONFIGURED",
            "Liga primeiro o e-Fatura com as tuas credenciais.",
        )
        try {
            val clientAlias = alias() ?: throw RuntimeBridgeException(
                "RUNTIME_NOT_CONFIGURED",
                "Seleciona primeiro um certificado cliente do dispositivo.",
            )
            val identity = loadIdentity(clientAlias)
            val created = try {
                FactIntWsProtocol.created(ntp.now())
            } catch (error: Exception) {
                throw RuntimeBridgeException(
                    "NTP_TIME_UNAVAILABLE",
                    "Não foi possível obter uma hora segura. Tenta novamente.",
                    error,
                )
            }
            val security = FactIntWsProtocol.securityMaterial(
                stored.password,
                created,
                cipherCertificates.load().publicKey,
            )
            val xml = FactIntWsProtocol.envelope(
                operation = operation,
                nif = stored.nif,
                year = Year.now(ZoneOffset.UTC).value,
                security = security,
                sectorCode = sectorCode,
                channelVersion = androidChannelVersion(),
            )
            val response = transport(operation, xml, identity)
            return FactIntWsResponseParser.parse(response, operation)
        } finally {
            stored.clear()
        }
    }

    private fun androidChannelVersion(): String {
        val release = Build.VERSION.RELEASE.replace(Regex("[^A-Za-z0-9._-]"), "")
        return "Android SDK: ${Build.VERSION.SDK_INT} ($release)"
    }

    private fun loadIdentity(alias: String): ClientIdentity {
        try {
            val key = KeyChain.getPrivateKey(context, alias)
                ?: throw RuntimeBridgeException(
                    "RUNTIME_NOT_CONFIGURED",
                    "O certificado cliente selecionado já não está disponível.",
                )
            val chain = KeyChain.getCertificateChain(context, alias)
            if (chain.isNullOrEmpty()) {
                throw RuntimeBridgeException(
                    "RUNTIME_NOT_CONFIGURED",
                    "A cadeia do certificado cliente está indisponível.",
                )
            }
            return ClientIdentity(alias, key, chain)
        } catch (error: RuntimeBridgeException) {
            throw error
        } catch (error: Exception) {
            throw RuntimeBridgeException(
                "RUNTIME_NOT_CONFIGURED",
                "Não foi possível usar o certificado cliente selecionado.",
                error,
            )
        }
    }

    private fun transport(
        operation: FactIntOperation,
        xml: String,
        identity: ClientIdentity,
    ): String {
        val trustFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
        trustFactory.init(null as KeyStore?)
        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(arrayOf<KeyManager>(SingleAliasKeyManager(identity)), trustFactory.trustManagers, null)
        val connection = URL(FactIntWsProtocol.ENDPOINT).openConnection() as HttpsURLConnection
        try {
            connection.sslSocketFactory = sslContext.socketFactory
            connection.hostnameVerifier = HttpsURLConnection.getDefaultHostnameVerifier()
            connection.requestMethod = "POST"
            connection.connectTimeout = 15_000
            connection.readTimeout = 30_000
            connection.instanceFollowRedirects = false
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "text/xml;charset=utf-8")
            connection.setRequestProperty("SOAPAction", FactIntWsProtocol.soapAction(operation))
            connection.setRequestProperty("Accept-Encoding", "gzip")
            connection.setRequestProperty("User-Agent", "ksoap2-android/2.6.0+")
            val requestBytes = xml.toByteArray(Charsets.UTF_8)
            connection.setFixedLengthStreamingMode(requestBytes.size)
            connection.outputStream.use { it.write(requestBytes) }
            requestBytes.fill(0)
            val status = connection.responseCode
            val source = if (status in 200..299) connection.inputStream else connection.errorStream
            val body = source?.let { readResponse(it, connection.contentEncoding) }.orEmpty()
            if (body.isEmpty()) {
                throw RuntimeBridgeException(
                    if (status in 200..299) "SOAP_PROTOCOL_ERROR" else "NETWORK_ERROR",
                    "O serviço devolveu uma resposta vazia.",
                )
            }
            return body
        } catch (error: RuntimeBridgeException) {
            throw error
        } catch (error: javax.net.ssl.SSLException) {
            throw RuntimeBridgeException(
                "TLS_ERROR",
                "Não foi possível estabelecer a ligação segura.",
                error,
            )
        } catch (error: java.net.SocketTimeoutException) {
            throw RuntimeBridgeException(
                "NETWORK_ERROR",
                "O serviço demorou demasiado tempo a responder.",
                error,
            )
        } catch (error: Exception) {
            throw RuntimeBridgeException(
                "NETWORK_ERROR",
                "Não foi possível contactar o serviço e-Fatura.",
                error,
            )
        } finally {
            connection.disconnect()
        }
    }

    private fun readResponse(stream: InputStream, contentEncoding: String?): String {
        val decoded = if (contentEncoding.equals("gzip", ignoreCase = true)) {
            GZIPInputStream(stream)
        } else {
            stream
        }
        return decoded.bufferedReader(Charsets.UTF_8).use { it.readText() }
    }
}

private data class ClientIdentity(
    val alias: String,
    val privateKey: PrivateKey,
    val chain: Array<X509Certificate>,
)

private class SingleAliasKeyManager(
    private val identity: ClientIdentity,
) : X509ExtendedKeyManager() {
    override fun chooseClientAlias(
        keyType: Array<out String>?,
        issuers: Array<out Principal>?,
        socket: Socket?,
    ): String = identity.alias

    override fun chooseEngineClientAlias(
        keyType: Array<out String>?,
        issuers: Array<out Principal>?,
        engine: SSLEngine?,
    ): String = identity.alias

    override fun getCertificateChain(alias: String?): Array<X509Certificate>? =
        if (alias == identity.alias) identity.chain else null

    override fun getPrivateKey(alias: String?): PrivateKey? =
        if (alias == identity.alias) identity.privateKey else null

    override fun getClientAliases(
        keyType: String?,
        issuers: Array<out Principal>?,
    ): Array<String> = arrayOf(identity.alias)

    override fun chooseServerAlias(
        keyType: String?,
        issuers: Array<out Principal>?,
        socket: Socket?,
    ): String? = null

    override fun getServerAliases(
        keyType: String?,
        issuers: Array<out Principal>?,
    ): Array<String>? = null
}

internal object FactIntWsResponseParser {
    fun parse(xml: String, operation: FactIntOperation): Map<String, Any?> {
        if (Regex("<!DOCTYPE|<!ENTITY", RegexOption.IGNORE_CASE).containsMatchIn(xml)) {
            throw RuntimeBridgeException(
                "PARSING_ERROR",
                "A resposta do serviço não tem um formato suportado.",
            )
        }
        val document = try {
            val factory = DocumentBuilderFactory.newInstance().apply {
                isNamespaceAware = true
                listOf(
                    "http://apache.org/xml/features/disallow-doctype-decl" to true,
                    "http://xml.org/sax/features/external-general-entities" to false,
                    "http://xml.org/sax/features/external-parameter-entities" to false,
                ).forEach { (feature, enabled) ->
                    runCatching { setFeature(feature, enabled) }
                }
                listOf(
                    "http://javax.xml.XMLConstants/property/accessExternalDTD",
                    "http://javax.xml.XMLConstants/property/accessExternalSchema",
                ).forEach { attribute ->
                    runCatching { setAttribute(attribute, "") }
                }
            }
            factory.newDocumentBuilder().parse(ByteArrayInputStream(xml.toByteArray(Charsets.UTF_8)))
        } catch (error: Exception) {
            throw RuntimeBridgeException(
                "PARSING_ERROR",
                "A resposta do serviço não tem um formato suportado.",
                error,
            )
        }
        text(document.documentElement, "faultcode")?.let { code ->
            val reason = sanitize(text(document.documentElement, "faultstring").orEmpty())
            val classification = when {
                Regex("auth|credential|password|username|utilizador", RegexOption.IGNORE_CASE)
                    .containsMatchIn("$code $reason") -> "AUTH_ERROR"
                Regex("authoriz|permiss|forbidden|acesso", RegexOption.IGNORE_CASE)
                    .containsMatchIn("$code $reason") -> "AUTHORIZATION_ERROR"
                else -> "SOAP_PROTOCOL_ERROR"
            }
            throw RuntimeBridgeException(classification, "O serviço rejeitou o pedido seguro.")
        }
        val response = first(document.documentElement, "${operation.wireName}Response")
            ?: throw RuntimeBridgeException(
                "PARSING_ERROR",
                "A resposta não corresponde à operação solicitada.",
            )
        val estado = requiredText(response, "EstadoOperacao")
        val description = sanitize(requiredText(response, "Desc"))
        if (estado !in setOf("200", "204")) {
            val code = if (Regex("auth|senha|utilizador", RegexOption.IGNORE_CASE)
                    .containsMatchIn(description)
            ) {
                "AUTH_ERROR"
            } else {
                "BUSINESS_ERROR"
            }
            throw RuntimeBridgeException(code, safeBusinessMessage(estado))
        }
        return when (operation) {
            FactIntOperation.OVERVIEW -> overview(response, estado)
            FactIntOperation.PENDING, FactIntOperation.SECTOR -> invoices(response, operation, estado)
        }
    }

    private fun overview(response: Element, estado: String): Map<String, Any?> {
        val sectors = elements(response, "Setor").mapNotNull { sector ->
            val code = text(sector, "CodSetor")?.let(::normalizeSectorCode) ?: return@mapNotNull null
            mapOf(
                "code" to code,
                "label" to text(sector, "DescSetor")?.takeIf(String::isNotBlank),
                "provisionalBenefitCents" to optionalMoney(sector, "ValorBeneficioProvisorioPorSetor"),
                "invoiceCount" to optionalInteger(sector, "NumFaturas"),
            )
        }
        return mapOf(
            "estadoOperacao" to estado,
            "provisionalBenefitCents" to requiredOverviewMoney(response, "ValorTotalBeneficioProvisorio"),
            "pendingValidation" to requiredOverviewInteger(response, "NumTotalFaturasPorValidar"),
            "pendingRevenueAssociation" to requiredOverviewInteger(
                response,
                "NumTotalFaturasPorAssociarReceita",
            ),
            "sectors" to sectors,
        )
    }

    private fun invoices(
        response: Element,
        operation: FactIntOperation,
        estado: String,
    ): Map<String, Any?> {
        val invoiceElements = elements(response, "Fatura")
        val parsed = invoiceElements.mapIndexed { index, invoice ->
            try {
                val identifier = requiredText(invoice, "IdDocumento")
                if (identifier.isBlank()) throw IllegalArgumentException("missing identifier")
                mapOf(
                    "date" to requiredDate(invoice, "DataDocumento"),
                    "totalCents" to requiredMoney(invoice, "ValorTotal"),
                    "issuerDisplayName" to text(invoice, "NomeEmitente")?.takeIf(String::isNotBlank),
                    "vatCents" to optionalMoney(invoice, "ValorIva"),
                    "sectorCode" to text(invoice, "CodSetor")?.let(::normalizeSectorCode),
                    "sectorLabel" to text(invoice, "DescSetor")?.takeIf(String::isNotBlank),
                    "classificationStatus" to text(invoice, "CodSetor")?.takeIf(String::isNotBlank),
                    "pendingClassification" to (operation == FactIntOperation.PENDING),
                )
            } catch (error: Exception) {
                throw RuntimeBridgeException(
                    "PARSING_ERROR",
                    "A fatura ${index + 1} tem um formato ainda não suportado.",
                    error,
                )
            }
        }
        if (parsed.size != invoiceElements.size) {
            throw RuntimeBridgeException(
                "PARSING_ERROR",
                "Nem todas as faturas devolvidas puderam ser interpretadas.",
            )
        }
        return mapOf(
            "estadoOperacao" to estado,
            "serverInvoiceCount" to invoiceElements.size,
            "parsedInvoiceCount" to parsed.size,
            "totalPages" to optionalInteger(response, "TotalPaginas"),
            "invoices" to parsed,
        )
    }

    private fun requiredText(parent: Element, name: String): String =
        text(parent, name)?.takeIf(String::isNotBlank)
            ?: throw RuntimeBridgeException(
                "PARSING_ERROR",
                "A resposta não contém todos os campos obrigatórios.",
            )

    private fun requiredDate(parent: Element, name: String): String {
        val value = requiredText(parent, name)
        if (!Regex("^\\d{4}-\\d{2}-\\d{2}$").matches(value)) {
            throw IllegalArgumentException("invalid date")
        }
        java.time.LocalDate.parse(value)
        return value
    }

    private fun requiredMoney(parent: Element, name: String): Long =
        optionalMoney(parent, name) ?: throw IllegalArgumentException("missing money")

    private fun requiredOverviewMoney(parent: Element, name: String): Long = try {
        requiredMoney(parent, name)
    } catch (error: Exception) {
        throw RuntimeBridgeException(
            "PARSING_ERROR",
            "A resposta não contém todos os campos obrigatórios.",
            error,
        )
    }

    private fun requiredOverviewInteger(parent: Element, name: String): Int = try {
        optionalInteger(parent, name) ?: throw IllegalArgumentException("missing integer")
    } catch (error: Exception) {
        throw RuntimeBridgeException(
            "PARSING_ERROR",
            "A resposta não contém todos os campos obrigatórios.",
            error,
        )
    }

    private fun optionalMoney(parent: Element, name: String): Long? {
        val value = text(parent, name)?.takeIf(String::isNotBlank) ?: return null
        val match = Regex("^(-?)(\\d+)(?:[.,](\\d{1,2}))?$").matchEntire(value)
            ?: throw IllegalArgumentException("invalid money")
        val whole = match.groupValues[2].toLongExact()
        val fraction = match.groupValues[3].padEnd(2, '0').ifEmpty { "0" }.toLongExact()
        val cents = Math.addExact(Math.multiplyExact(whole, 100L), fraction)
        return if (match.groupValues[1] == "-") Math.negateExact(cents) else cents
    }

    private fun optionalInteger(parent: Element, name: String): Int? {
        val value = text(parent, name)?.takeIf(String::isNotBlank) ?: return null
        if (!Regex("^\\d+$").matches(value)) throw IllegalArgumentException("invalid integer")
        return value.toInt()
    }

    private fun String.toLongExact(): Long = toLongOrNull()
        ?: throw IllegalArgumentException("numeric value out of range")

    private fun normalizeSectorCode(raw: String): String {
        val value = raw.trim().uppercase()
        return when {
            Regex("^C(?:0[1-9]|1[0-5]|99)$").matches(value) -> value
            Regex("^(?:0[1-9]|1[0-5]|99)$").matches(value) -> "C$value"
            else -> value
        }
    }

    private fun elements(parent: Element, localName: String): List<Element> {
        val result = mutableListOf<Element>()
        val nodes = parent.getElementsByTagNameNS("*", localName)
        for (index in 0 until nodes.length) {
            (nodes.item(index) as? Element)?.let(result::add)
        }
        return result
    }

    private fun first(parent: Element, localName: String): Element? =
        elements(parent, localName).firstOrNull()

    private fun text(parent: Element, localName: String): String? =
        first(parent, localName)?.textContent?.trim()

    private fun sanitize(value: String): String = value
        .replace(Regex("(?<!\\d)\\d{9}(?!\\d)"), "[IDENTIFICADOR REMOVIDO]")
        .take(240)

    private fun safeBusinessMessage(code: String): String = when (code) {
        "419" -> "O serviço não disponibilizou estes dados para o período selecionado."
        else -> "O serviço e-Fatura não conseguiu concluir a consulta."
    }
}
