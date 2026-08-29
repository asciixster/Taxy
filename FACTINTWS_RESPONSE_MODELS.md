# FactIntWS response models

## Common result and errors

Successful operation wrappers carry `WSResult/EstadoOperacao` and `WSResult/Desc`. Meanings are preserved as opaque server values until runtime or official documentation establishes semantics. SOAP faults are parsed separately. The app additionally recognizes an authentication wrapper containing `AuthenticationException/AuthenticationFailed/message` and generic SOAP `faultcode`/`faultstring` server errors.

## FactInt invoice wire model

The official DTO contains: `ATCUD`, `CanalRegisto`, `CodSetor`, `DataDocumento`, `FAmbActProfissional`, `IdDocumento`, `NifEmitente`, `NomeEmitente`, `NumeroFatura`, `OrigemRegisto`, `Receita`, `ValorIncentivoConsumo`, `ValorIva`, `ValorProvisorioBeneficioDespesasGerais`, `ValorProvisorioBeneficioSetor`, and `ValorTotal`.

Taxy's `FactIntInvoiceResponse` parser keeps this full observed wire contract separate from a minimal `AtInvoiceDomain` projection. It preserves document type, channels/origin, recipe and manipulation flags, and every observed monetary component. Money is converted directly from decimal text to integer cents; date-only values remain `YYYY-MM-DD`. No FactInt DTO is forced into the fatshare wire model.

## Offline parser coverage

Synthetic fixtures cover a successful multi-invoice response, empty response, optional absent field, unknown element, malformed date, SOAP fault, and the app-observed authentication-error wrapper. Fixtures use obviously synthetic identifiers and contain no real tax, document, credential or certificate data.

Completeness: the four prioritized read-only response DTOs are structurally complete for fields visible in the APK. Actual cardinality/nullability edge cases and server business-code meanings remain runtime unknown.
