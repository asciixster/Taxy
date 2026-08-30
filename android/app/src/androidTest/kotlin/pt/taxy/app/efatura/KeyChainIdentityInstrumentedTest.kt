package pt.taxy.app.efatura

import android.content.Context
import android.os.Bundle
import android.security.KeyChain
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.security.MessageDigest
import java.security.Signature
import java.security.interfaces.RSAPublicKey
import javax.net.ssl.SSLContext
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class KeyChainIdentityInstrumentedTest {
    @Test
    fun androidXmlRuntimeParsesSyntheticOverview() {
        val xml = """<?xml version="1.0" encoding="UTF-8"?>
            <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body><EcraInicialResponse>
                <ValorTotalBeneficioProvisorio>0</ValorTotalBeneficioProvisorio>
                <NumTotalFaturasPorValidar>0</NumTotalFaturasPorValidar>
                <NumTotalFaturasPorAssociarReceita>0</NumTotalFaturasPorAssociarReceita>
                <ListaSetores><Setor><CodSetor>C01</CodSetor>
                  <ValorBeneficioProvisorioPorSetor>0</ValorBeneficioProvisorioPorSetor>
                </Setor></ListaSetores>
                <WSResult><EstadoOperacao>200</EstadoOperacao><Desc>OK</Desc></WSResult>
              </EcraInicialResponse></soap:Body>
            </soap:Envelope>""".trimIndent()
        val result = FactIntWsResponseParser.parse(xml, FactIntOperation.OVERVIEW)
        assertEquals("200", result["estadoOperacao"])
        assertEquals(0L, result["provisionalBenefitCents"])
        assertEquals(0, result["pendingValidation"])
    }

    @Test
    fun selectedIdentityMatchesRuntimeConfirmedPublicChain() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val arguments = InstrumentationRegistry.getArguments()
        val expectedLeaf = arguments.getString("expectedLeafCertificateSha256")
        val expectedSpki = arguments.getString("expectedLeafSpkiSha256")
        val expectedChain = arguments.getString("expectedChainSha256")
            ?.split(',')
            ?.filter(String::isNotBlank)
            ?.toSet()
            .orEmpty()
        assertTrue(expectedLeaf?.matches(Regex("^[0-9a-f]{64}$")) == true)
        assertTrue(expectedSpki?.matches(Regex("^[0-9a-f]{64}$")) == true)
        assertTrue(expectedChain.isNotEmpty())

        val alias = context.getSharedPreferences(
            "taxy_efatura_runtime_v1",
            Context.MODE_PRIVATE,
        ).getString("client_alias", null)
        val selectedAlias = requireNotNull(alias)
        val privateKey = requireNotNull(KeyChain.getPrivateKey(context, selectedAlias))
        val chain = requireNotNull(KeyChain.getCertificateChain(context, selectedAlias))
        assertTrue(chain.isNotEmpty())
        instrumentation.sendStatus(2, Bundle().apply {
            putInt("android_chain_length", chain.size)
        })

        val leaf = chain.first()
        assertEquals(expectedLeaf, sha256(leaf.encoded))
        assertEquals(expectedSpki, sha256(leaf.publicKey.encoded))
        assertTrue(chain.all { sha256(it.encoded) in expectedChain })
        chain.toList().zipWithNext().forEach { (child, issuer) ->
            assertEquals(child.issuerX500Principal, issuer.subjectX500Principal)
        }

        val challenge = "taxy-keychain-identity-proof-v1".toByteArray(Charsets.UTF_8)
        val signer = Signature.getInstance("SHA256withRSA").apply {
            initSign(privateKey)
            update(challenge)
        }
        val signature = signer.sign()
        val verifier = Signature.getInstance("SHA256withRSA").apply {
            initVerify(leaf.publicKey)
            update(challenge)
        }
        assertTrue(verifier.verify(signature))
        challenge.fill(0)
        signature.fill(0)

        assertEquals("RSA", privateKey.algorithm)
        assertEquals("RSA", leaf.publicKey.algorithm)
        assertTrue((leaf.publicKey as RSAPublicKey).modulus.bitLength() >= 2048)
        assertTrue(leaf.extendedKeyUsage?.contains(CLIENT_AUTH_EKU) == true)
        assertTrue(leaf.keyUsage?.getOrNull(0) == true)

        val supported = SSLContext.getInstance("TLS").apply { init(null, null, null) }
            .supportedSSLParameters
        assertTrue("TLSv1.3" in supported.protocols)
        assertTrue("TLS_AES_128_GCM_SHA256" in supported.cipherSuites)

    }

    private fun sha256(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }

    private companion object {
        const val CLIENT_AUTH_EKU = "1.3.6.1.5.5.7.3.2"
    }
}
