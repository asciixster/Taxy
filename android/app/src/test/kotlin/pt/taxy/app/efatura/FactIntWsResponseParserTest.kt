package pt.taxy.app.efatura

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class FactIntWsResponseParserTest {
    @Test
    fun `overview maps only normalized aggregates`() {
        val parsed = FactIntWsResponseParser.parse(overviewXml, FactIntOperation.OVERVIEW)
        assertEquals(50339L, parsed["provisionalBenefitCents"])
        assertEquals(5, parsed["pendingValidation"])
        val sectors = parsed["sectors"] as List<*>
        val sector = sectors.single() as Map<*, *>
        assertEquals("C05", sector["code"])
        assertEquals(234L, sector["provisionalBenefitCents"])
    }

    @Test
    fun `overview missing required aggregate fails closed instead of becoming zero`() {
        val error = assertFailsWith<RuntimeBridgeException> {
            FactIntWsResponseParser.parse(
                overviewXml.replace(
                    "<app:NumTotalFaturasPorValidar>5</app:NumTotalFaturasPorValidar>",
                    "",
                ),
                FactIntOperation.OVERVIEW,
            )
        }
        assertEquals("PARSING_ERROR", error.code)
    }

    @Test
    fun `invoice parser preserves count and integer cents`() {
        val parsed = FactIntWsResponseParser.parse(invoiceXml, FactIntOperation.PENDING)
        assertEquals(1, parsed["serverInvoiceCount"])
        assertEquals(1, parsed["parsedInvoiceCount"])
        val invoice = (parsed["invoices"] as List<*>).single() as Map<*, *>
        assertEquals(2345L, invoice["totalCents"])
        assertEquals(true, invoice["pendingClassification"])
        assertEquals(null, invoice["issuerTaxId"])
        assertEquals(null, invoice["documentId"])
    }

    @Test
    fun `business 419 remains unknown and safely classified`() {
        val error = assertFailsWith<RuntimeBridgeException> {
            FactIntWsResponseParser.parse(
                overviewXml.replace(
                    "<app:EstadoOperacao>200",
                    "<app:EstadoOperacao>419",
                ),
                FactIntOperation.OVERVIEW,
            )
        }
        assertEquals("BUSINESS_ERROR", error.code)
        assertEquals(
            "O serviço não disponibilizou estes dados para o período selecionado.",
            error.safeMessage,
        )
    }

    @Test
    fun `malformed invoice fails closed without dropping it`() {
        val error = assertFailsWith<RuntimeBridgeException> {
            FactIntWsResponseParser.parse(
                invoiceXml.replace("<ValorTotal>23.45</ValorTotal>", "<ValorTotal>23.456</ValorTotal>"),
                FactIntOperation.PENDING,
            )
        }
        assertEquals("PARSING_ERROR", error.code)
    }

    private companion object {
        val overviewXml = """
            <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
              <env:Body><app:EcraInicialResponse xmlns:app="http://factemi.at.min_financas.pt/factintws">
                <app:ListaSetores><app:Setor><app:ValorBeneficioProvisorioPorSetor>2.34</app:ValorBeneficioProvisorioPorSetor>
                  <app:CodSetor>05</app:CodSetor>
                </app:Setor></app:ListaSetores>
                <app:ValorTotalBeneficioProvisorio>503.39</app:ValorTotalBeneficioProvisorio>
                <app:NumTotalFaturasPorValidar>5</app:NumTotalFaturasPorValidar>
                <app:NumTotalFaturasPorAssociarReceita>1</app:NumTotalFaturasPorAssociarReceita>
                <app:WSResult><app:Desc>Synthetic</app:Desc><app:EstadoOperacao>200</app:EstadoOperacao></app:WSResult>
              </app:EcraInicialResponse></env:Body>
            </env:Envelope>
        """.trimIndent()

        val invoiceXml = """
            <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
              <env:Body><FaturasPorClassificarResponse>
                <ListaFaturasPorClassificar><Fatura>
                  <IdDocumento>SYNTHETIC</IdDocumento><DataDocumento>2026-08-29</DataDocumento>
                  <ValorTotal>23.45</ValorTotal><ValorIva>4.39</ValorIva>
                </Fatura></ListaFaturasPorClassificar>
                <WSResult><EstadoOperacao>200</EstadoOperacao><Desc>Synthetic</Desc></WSResult>
              </FaturasPorClassificarResponse></env:Body>
            </env:Envelope>
        """.trimIndent()
    }
}
