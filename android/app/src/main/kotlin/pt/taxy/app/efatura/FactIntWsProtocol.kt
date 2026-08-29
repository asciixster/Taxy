package pt.taxy.app.efatura

import java.nio.ByteBuffer
import java.security.MessageDigest
import java.security.PublicKey
import java.security.SecureRandom
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec

internal enum class FactIntOperation(val wireName: String) {
    OVERVIEW("EcraInicial"),
    PENDING("FaturasPorClassificar"),
    SECTOR("FaturasPorSetor"),
}

internal data class FactIntSecurityMaterial(
    val encryptedPassword: String,
    val encryptedDigest: String,
    val encryptedNonce: String,
    val created: String,
)

internal object FactIntWsProtocol {
    const val ENDPOINT = "https://servicos.portaldasfinancas.gov.pt:8443/mobile/a4/factintws/ws"
    const val HOST = "servicos.portaldasfinancas.gov.pt"
    const val NAMESPACE = "http://factemi.at.min_financas.pt/factintws"
    private const val SOAP_NAMESPACE = "http://schemas.xmlsoap.org/soap/envelope/"
    private const val WSSE_NAMESPACE = "http://schemas.xmlsoap.org/ws/2002/12/secext"
    private const val AUTH_NAMESPACE = "http://at.pt/wsp/auth"
    private const val ACTOR = "http://at.pt/actor/SPA"
    private val createdFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        .withZone(ZoneOffset.UTC)

    fun created(instant: Instant): String = createdFormatter.format(instant)

    fun securityMaterial(
        password: CharArray,
        created: String,
        publicKey: PublicKey,
        aesKey: ByteArray = ByteArray(16).also(SecureRandom()::nextBytes),
    ): FactIntSecurityMaterial {
        require(aesKey.size == 16) { "FactIntWS AES key must contain 16 bytes" }
        val key = aesKey.copyOf()
        val passwordBytes = password.concatToString().toByteArray(Charsets.UTF_8)
        val createdBytes = created.toByteArray(Charsets.UTF_8)
        return try {
            val digest = MessageDigest.getInstance("SHA-1").digest(
                ByteBuffer.allocate(key.size + createdBytes.size + passwordBytes.size)
                    .put(key)
                    .put(createdBytes)
                    .put(passwordBytes)
                    .array(),
            )
            val rsa = Cipher.getInstance("RSA/ECB/PKCS1Padding")
            rsa.init(Cipher.ENCRYPT_MODE, publicKey)
            FactIntSecurityMaterial(
                encryptedPassword = aesEncrypt(key, passwordBytes),
                encryptedDigest = aesEncrypt(key, digest),
                encryptedNonce = base64(rsa.doFinal(key)),
                created = created,
            ).also { digest.fill(0) }
        } finally {
            passwordBytes.fill(0)
            createdBytes.fill(0)
            key.fill(0)
        }
    }

    fun envelope(
        operation: FactIntOperation,
        nif: String,
        year: Int,
        security: FactIntSecurityMaterial,
        sectorCode: String? = null,
        channelSystem: String = "A",
        channelVersion: String,
    ): String {
        require(Regex("^\\d{9}$").matches(nif)) { "Invalid NIF" }
        require(year in 2000..9999) { "Invalid year" }
        val body = when (operation) {
            FactIntOperation.OVERVIEW, FactIntOperation.PENDING ->
                "<app:Nif>${xml(nif)}</app:Nif><app:Ano>$year</app:Ano>${channel(channelSystem, channelVersion)}"
            FactIntOperation.SECTOR -> {
                require(Regex("^C(?:0[1-9]|1[0-5]|99)$").matches(sectorCode.orEmpty())) {
                    "Invalid sector"
                }
                "<app:NifAdquirente>${xml(nif)}</app:NifAdquirente>" +
                    "<app:CodSetor>${xml(sectorCode!!)}</app:CodSetor>" +
                    "<app:Ano>$year</app:Ano><app:Indice>0</app:Indice>${channel(channelSystem, channelVersion)}"
            }
        }
        return "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>" +
            "<S:Envelope xmlns:S=\"$SOAP_NAMESPACE\"><S:Header>" +
            "<wss:Security xmlns:at=\"$AUTH_NAMESPACE\" xmlns:wss=\"$WSSE_NAMESPACE\" " +
            "S:Actor=\"$ACTOR\" at:Version=\"2\"><wss:UsernameToken>" +
            "<wss:Username>${xml(nif)}</wss:Username>" +
            "<wss:Password Digest=\"${xml(security.encryptedDigest)}\">" +
            "${xml(security.encryptedPassword)}</wss:Password>" +
            "<wss:Nonce>${xml(security.encryptedNonce)}</wss:Nonce>" +
            "<wss:Created>${xml(security.created)}</wss:Created>" +
            "</wss:UsernameToken></wss:Security></S:Header><S:Body>" +
            "<app:${operation.wireName}Request xmlns:app=\"$NAMESPACE\">$body" +
            "</app:${operation.wireName}Request></S:Body></S:Envelope>"
    }

    fun soapAction(operation: FactIntOperation): String = "$NAMESPACE/${operation.wireName}"

    private fun channel(system: String, version: String): String {
        require(system == "A") { "Invalid channel system" }
        require(version.matches(Regex("^Android SDK: \\d{1,3} \\([A-Za-z0-9._-]{1,32}\\)$"))) {
            "Invalid channel version"
        }
        return "<app:CanalOrigem><app:Sistema>${xml(system)}</app:Sistema>" +
            "<app:Versao>${xml(version)}</app:Versao></app:CanalOrigem>"
    }

    private fun aesEncrypt(key: ByteArray, plaintext: ByteArray): String {
        val cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"))
        return base64(cipher.doFinal(plaintext))
    }

    private fun base64(input: ByteArray): String {
        val alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        val output = StringBuilder(((input.size + 2) / 3) * 4)
        var index = 0
        while (index < input.size) {
            val first = input[index++].toInt() and 0xff
            val second = if (index < input.size) input[index++].toInt() and 0xff else -1
            val third = if (index < input.size) input[index++].toInt() and 0xff else -1
            output.append(alphabet[first ushr 2])
            output.append(alphabet[((first and 0x03) shl 4) or if (second >= 0) second ushr 4 else 0])
            output.append(if (second >= 0) alphabet[((second and 0x0f) shl 2) or if (third >= 0) third ushr 6 else 0] else '=')
            output.append(if (third >= 0) alphabet[third and 0x3f] else '=')
        }
        return output.toString()
    }

    private fun xml(value: String): String = value
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
        .replace("'", "&apos;")
}
