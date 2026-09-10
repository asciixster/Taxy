package pt.taxy.app.dm3irs

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class Dm3IrsStructuralParserTest {
    @Test
    fun `known 2024 template yields only runtime-confirmed exact fields`() {
        val result = Dm3IrsStructuralParser.parse(template())
        assertEquals(2024, result.taxYear)
        assertEquals(setOf("A", "C", "H", "SS"), result.annexes)
        assertEquals(setOf("A", "B"), result.categories)
        assertEquals("CONTABILIDADE_ORGANIZADA", result.categoryBRegime)
        assertEquals("4015", result.activityCode)
        assertEquals(12345, result.taxableProfitCents)
        assertEquals(23456, result.withholdingCents)
        assertEquals(10, result.exactCount)
    }

    @Test
    fun `unknown page structure fails closed`() {
        assertFailsWith<UnknownDm3IrsTemplate> {
            Dm3IrsStructuralParser.parse(template().dropLast(1))
        }
    }

    @Test
    fun `missing runtime anchor fails closed`() {
        val pages = template().map { page ->
            if (page.number == 7) page.copy(tokens = page.tokens.filterNot { it.text == "470" }) else page
        }
        assertFailsWith<UnknownDm3IrsTemplate> { Dm3IrsStructuralParser.parse(pages) }
    }

    @Test
    fun `ambiguous field cell fails closed`() {
        val pages = template().map { page ->
            if (page.number == 7) page.copy(tokens = page.tokens + token("345,67", .88, .115)) else page
        }
        assertFailsWith<UnknownDm3IrsTemplate> { Dm3IrsStructuralParser.parse(pages) }
    }

    @Test
    fun `empty is distinct from zero`() {
        val empty = template().map { page ->
            if (page.number == 7) page.copy(tokens = page.tokens.filterNot { it.text == "234,56" }) else page
        }
        assertFailsWith<UnknownDm3IrsTemplate> { Dm3IrsStructuralParser.parse(empty) }
        assertEquals(0, Dm3IrsStructuralParser.parseMoneyCents("0,00"))
    }

    @Test
    fun `Portuguese money is integer cents`() {
        assertEquals(123456, Dm3IrsStructuralParser.parseMoneyCents("1.234,56"))
        assertEquals(123456, Dm3IrsStructuralParser.parseMoneyCents("1 234,56"))
        assertNull(Dm3IrsStructuralParser.parseMoneyCents("1.234"))
    }

    @Test
    fun `field 603 remains runtime-validation gated and absent from product map`() {
        val result = Dm3IrsStructuralParser.parse(template()).toMap()
        assertEquals("603", Dm3IrsStructuralParser.RUNTIME_VALIDATION_REQUIRED_FIELD_603)
        assertFalse(result.keys.any { it.contains("603") || it.contains("pagamentos", ignoreCase = true) })
    }

    @Test
    fun `duplicate annex heading fails closed`() {
        val pages = template().map { page ->
            if (page.number == 6) page.copy(tokens = page.tokens + heading("H")) else page
        }
        assertFailsWith<UnknownDm3IrsTemplate> { Dm3IrsStructuralParser.parse(pages) }
    }

    @Test
    fun `network allowlist contains reads only`() {
        assertEquals(3, Dm3IrsProtocol.allowedOperations.size)
        assertTrue(Dm3IrsProtocol.allowedOperations.all { it != "submeterDeclaracaoMobileRequest" })
        assertEquals(setOf("submeterDeclaracaoMobileRequest"), Dm3IrsProtocol.prohibitedOperations)
    }

    @Test
    fun `protocol fixes 2024 and exact SOAP actions`() {
        assertTrue(Dm3IrsProtocol.checkDeliveryBody(2024, "999999990").contains("ano-fiscal>2024"))
        assertFailsWith<IllegalArgumentException> { Dm3IrsProtocol.checkDeliveryBody(2025, "999999990") }
        assertEquals("tns:checkEntregaDeclMobileRequest", Dm3IrsProtocol.soapAction(Dm3IrsReadOperation.CHECK_DELIVERY))
        assertEquals("tns:obterReceiptMobileRequest", Dm3IrsProtocol.soapAction(Dm3IrsReadOperation.GET_RECEIPT))
        assertEquals("tns:obterDeclaracaoMobileRequest", Dm3IrsProtocol.soapAction(Dm3IrsReadOperation.GET_DECLARATION))
    }

    private fun template(): List<RecognizedPage> {
        val pages = (1..17).map { RecognizedPage(it, 1000, 1400, mutableListOf(token("2024", .1, .1))) }.toMutableList()
        pages[2] = pages[2].copy(tokens = heading("A"))
        pages[4] = pages[4].copy(tokens = heading("C") + listOf(
            token("01", .586, .073), token("X", .612, .074),
            token("07", .097, .233), token("4015", .176, .233),
        ))
        pages[6] = pages[6].copy(tokens = listOf(
            token("470", .753, .115), token("123,45", .870, .115),
            token("602", .291, .332), token("234,56", .433, .332),
            token("603", .511, .332),
        ))
        pages[13] = pages[13].copy(tokens = heading("H"))
        pages[16] = pages[16].copy(tokens = heading("SS"))
        return pages
    }

    private fun heading(annex: String): List<RecognizedToken> = listOf(
        token("MODELO", .05, .03), token("3", .12, .03),
        token("ANEXO", .20, .06), token(annex, .29, .06), token("2024", .8, .04),
    )

    private fun token(text: String, left: Double, top: Double) =
        RecognizedToken(text, left, top, left + .02, top + .01)
}
