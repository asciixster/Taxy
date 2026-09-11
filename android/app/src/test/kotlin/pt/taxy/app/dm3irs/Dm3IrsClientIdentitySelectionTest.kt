package pt.taxy.app.dm3irs

import java.security.Principal
import java.security.cert.X509Certificate
import javax.security.auth.x500.X500Principal
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class Dm3IrsClientIdentitySelectionTest {
    @Test
    fun `RSA identity is selected only for compatible TLS key types`() {
        assertTrue(Dm3IrsClientIdentitySelection.acceptsKeyTypes(arrayOf("EC", "RSA"), "RSA"))
        assertTrue(Dm3IrsClientIdentitySelection.acceptsKeyTypes(arrayOf("RSASSA-PSS"), "RSA"))
        assertFalse(Dm3IrsClientIdentitySelection.acceptsKeyTypes(arrayOf("EC"), "RSA"))
        assertFalse(Dm3IrsClientIdentitySelection.acceptsKeyTypes(null, "RSA"))
    }

    @Test
    fun `issuer selection accepts only an authority represented by the chain`() {
        val authority = X500Principal("CN=Taxy Test Authority")
        val other = X500Principal("CN=Other Authority")
        val certificate = StubCertificate(
            subject = X500Principal("CN=Taxy Client"),
            issuer = authority,
        )

        assertTrue(Dm3IrsClientIdentitySelection.acceptsIssuers(null, arrayOf(certificate)))
        assertTrue(
            Dm3IrsClientIdentitySelection.acceptsIssuers(
                arrayOf<Principal>(authority),
                arrayOf(certificate),
            ),
        )
        assertFalse(
            Dm3IrsClientIdentitySelection.acceptsIssuers(
                arrayOf<Principal>(other),
                arrayOf(certificate),
            ),
        )
    }
}

private class StubCertificate(
    private val subject: X500Principal,
    private val issuer: X500Principal,
) : X509Certificate() {
    override fun getSubjectX500Principal(): X500Principal = subject
    override fun getIssuerX500Principal(): X500Principal = issuer
    override fun checkValidity() = Unit
    override fun checkValidity(date: java.util.Date?) = Unit
    override fun getVersion(): Int = 3
    override fun getSerialNumber(): java.math.BigInteger = java.math.BigInteger.ONE
    override fun getIssuerDN(): Principal = issuer
    override fun getSubjectDN(): Principal = subject
    override fun getNotBefore(): java.util.Date = java.util.Date(0)
    override fun getNotAfter(): java.util.Date = java.util.Date(Long.MAX_VALUE)
    override fun getTBSCertificate(): ByteArray = byteArrayOf()
    override fun getSignature(): ByteArray = byteArrayOf()
    override fun getSigAlgName(): String = "NONE"
    override fun getSigAlgOID(): String = "0.0"
    override fun getSigAlgParams(): ByteArray? = null
    override fun getIssuerUniqueID(): BooleanArray? = null
    override fun getSubjectUniqueID(): BooleanArray? = null
    override fun getKeyUsage(): BooleanArray? = null
    override fun getBasicConstraints(): Int = -1
    override fun getEncoded(): ByteArray = byteArrayOf()
    override fun verify(key: java.security.PublicKey?) = Unit
    override fun verify(key: java.security.PublicKey?, sigProvider: String?) = Unit
    override fun toString(): String = "StubCertificate"
    override fun getPublicKey(): java.security.PublicKey? = null
    override fun hasUnsupportedCriticalExtension(): Boolean = false
    override fun getCriticalExtensionOIDs(): MutableSet<String>? = null
    override fun getNonCriticalExtensionOIDs(): MutableSet<String>? = null
    override fun getExtensionValue(oid: String?): ByteArray? = null
}
