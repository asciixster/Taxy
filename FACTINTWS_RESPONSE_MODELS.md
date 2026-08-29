# FactIntWS response models

## Common result and errors

Successful operation wrappers carry `WSResult/EstadoOperacao` and `WSResult/Desc`. Meanings are preserved as opaque server values until runtime or official documentation establishes semantics. SOAP faults are parsed separately. The app additionally recognizes an authentication wrapper containing `AuthenticationException/AuthenticationFailed/message` and generic SOAP `faultcode`/`faultstring` server errors.

## FactInt invoice wire model

The official DTO contains: `ATCUD`, `CanalRegisto`, `CodSetor`, `DataDocumento`, `FAmbActProfissional`, `IdDocumento`, `NifEmitente`, `NomeEmitente`, `NumeroFatura`, `OrigemRegisto`, `Receita`, `ValorIncentivoConsumo`, `ValorIva`, `ValorProvisorioBeneficioDespesasGerais`, `ValorProvisorioBeneficioSetor`, and `ValorTotal`.

Taxy's `FactIntInvoiceResponse`, `FactIntPendingInvoiceResponse`, `FactIntInvoicePageResponse`, and `FactIntSectorResponse` keep this observed wire contract separate from `AtInvoiceDomain`. The domain projection deliberately excludes issuer and document identifiers. It preserves only fields needed by a future UI: source, date, integer-cent amounts, sector, opaque classification/status values, professional flag, manipulation capability, channel, document type and pending state. Unknown codes are represented as `unknown(rawCode)` and are never guessed. No FactInt DTO is forced into the fatshare wire model.

## Offline parser coverage

Synthetic fixtures cover a successful multi-invoice response, empty response, optional absent field, unknown element, malformed date, SOAP fault, and the app-observed authentication-error wrapper. Fixtures use obviously synthetic identifiers and contain no real tax, document, credential or certificate data.

Completeness: `EcraInicial` is consolidated and the two invoice operations are runtime-confirmed for empty responses. Actual real-invoice cardinality/nullability, field presence and business-code meanings remain runtime unknown because both controlled calls returned zero invoices.
