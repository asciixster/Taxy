package pt.taxy.app.dm3irs

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class Dm3IrsSafeXmlTest {
    @Test
    fun `parses namespace-aware SOAP without relying on every optional parser feature`() {
        val xml = """
            <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body><response xmlns="urn:test"><codigo>0</codigo></response></soap:Body>
            </soap:Envelope>
        """.trimIndent().toByteArray()

        val document = Dm3IrsSafeXml.parse(xml)

        assertEquals(1, document.getElementsByTagNameNS("*", "codigo").length)
    }

    @Test
    fun `rejects doctype before invoking the platform parser`() {
        val xml = """
            <!DOCTYPE response [<!ENTITY secret SYSTEM "file:///data/local/tmp/secret">]>
            <response>&secret;</response>
        """.trimIndent().toByteArray()

        assertFailsWith<IllegalArgumentException> { Dm3IrsSafeXml.parse(xml) }
    }

    @Test
    fun `rejects non UTF-8 XML so declarations cannot bypass the preflight`() {
        val utf16 = "<response><codigo>0</codigo></response>".toByteArray(Charsets.UTF_16)

        assertFailsWith<IllegalArgumentException> { Dm3IrsSafeXml.parse(utf16) }
    }
}
