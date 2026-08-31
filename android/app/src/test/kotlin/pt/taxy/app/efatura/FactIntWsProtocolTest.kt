package pt.taxy.app.efatura

import java.security.KeyPairGenerator
import java.time.Instant
import javax.crypto.Cipher
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class FactIntWsProtocolTest {
    @Test
    fun `crypto vector matches Node reference implementation`() {
        val keyPair = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
        val aesKey = ByteArray(16) { it.toByte() }
        val material = FactIntWsProtocol.securityMaterial(
            password = "synthetic-password".toCharArray(),
            created = "2026-08-29T12:34:56.789Z",
            publicKey = keyPair.public,
            aesKey = aesKey,
        )
        assertEquals(
            "5+VGcbAcFdzx/kpX/SVhJ/5t1gRuHOUuQYX7311plKo=",
            material.encryptedPassword,
        )
        assertEquals(
            "AjdFwLJlXEKpjMHctroOhu/BUA3ZGCEREDzLpg5mAdM=",
            material.encryptedDigest,
        )
        val decrypt = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        decrypt.init(Cipher.DECRYPT_MODE, keyPair.private)
        assertContentEquals(aesKey, decrypt.doFinal(java.util.Base64.getDecoder().decode(material.encryptedNonce)))
    }

    @Test
    fun `Created uses exact UTC millisecond format`() {
        assertEquals(
            "2026-08-29T12:34:56.789Z",
            FactIntWsProtocol.created(Instant.parse("2026-08-29T12:34:56.789Z")),
        )
    }

    @Test
    fun `EcraInicial envelope preserves security and body order`() {
        val envelope = FactIntWsProtocol.envelope(
            operation = FactIntOperation.OVERVIEW,
            nif = "000000000",
            year = 2026,
            security = FactIntSecurityMaterial("PASSWORD", "DIGEST", "NONCE", "CREATED"),
            channelVersion = "Android SDK: 35 (15)",
        )
        assertTrue(envelope.indexOf("<wss:Username>") < envelope.indexOf("<wss:Password"))
        assertTrue(envelope.indexOf("<wss:Password") < envelope.indexOf("<wss:Nonce>"))
        assertTrue(envelope.indexOf("<wss:Nonce>") < envelope.indexOf("<wss:Created>"))
        assertTrue(envelope.indexOf("<app:Nif>") < envelope.indexOf("<app:Ano>"))
        assertTrue(envelope.indexOf("<app:Ano>") < envelope.indexOf("<app:CanalOrigem>"))
        assertTrue(envelope.contains("<app:Sistema>A</app:Sistema>"))
        assertTrue(envelope.contains("<app:Versao>Android SDK: 35 (15)</app:Versao>"))
    }

    @Test
    fun `write operations do not exist in runtime enum`() {
        assertEquals(
            setOf("EcraInicial", "FaturasPorClassificar", "FaturasPorSetor"),
            FactIntOperation.entries.map { it.wireName }.toSet(),
        )
    }
}
