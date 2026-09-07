# DM3IRS Mobile operation catalog

## Result

Static analysis of the official IRS Android package reconstructs seven operations: six read-only operations and one write. All use SOAP 1.1 over `POST` to the same environment-specific service path. This is an official-app-private contract, not a documented public API.

Production endpoint: `https://servicos.portaldasfinancas.gov.pt:411/ws/dm3irsMobileService/`

Quality endpoint: `https://servicos.portaldasfinancas.gov.pt:711/ws/dm3irsMobileService/`

Common namespaces:

- envelope: `http://schemas.xmlsoap.org/soap/envelope/`
- mobile schema (`sch`): `https://servicos.portaldasfinancas.gov.pt/dm3irsmobile/schemas`
- Modelo 3 schema (`sch1`): `https://servicos.portaldasfinancas.gov.pt/dm3irs/schemas`
- authentication: `http://at.pt/wsp/auth`
- WS-Security: `http://schemas.xmlsoap.org/ws/2002/12/secext`

`Content-Type` is `text/xml`. `SOAPAction` is the literal `tns:` followed by the request operation name. The request operation is also the single element below `S:Body`.

## Canonical contracts

| Operation | SOAPAction | Ordered request body | Parsed response | Semantics | Confidence |
|---|---|---|---|---|---|
| `obterCatalogosMobileRequest` | `tns:obterCatalogosMobileRequest` | `sch:tipoCatalogo` | `tipoCatalogo`, `detalheCatalogoJsonCdata` | read-only catalog lookup | EXACT request / HIGH response |
| `infoUtilizadorAutenticadoMobileRequest` | `tns:infoUtilizadorAutenticadoMobileRequest` | optional `sch:ano-fiscal`, optional `sch:nif` | `AuthUserInformation` and nested user/profile models | read-only authenticated-user profile | EXACT / HIGH |
| `infoAgregadoMobileRequest` | `tns:infoAgregadoMobileRequest` | `sch:ano-fiscal`, `sch:utilizadorAutenticado`, optional `sch:conjuge`, `sch:incluirConjuge`, repeated `sch:dependentes` | `AuthUserInformation`, including income, expense and calculation groups | read-only household/declaration context calculation | EXACT / HIGH |
| `checkEntregaDeclMobileRequest` | `tns:checkEntregaDeclMobileRequest` | `sch:ano-fiscal`, `sch:nif` | optional `declaracao` identifier plus status | read-only delivery-existence check | EXACT / HIGH |
| `obterReceiptMobileRequest` | `tns:obterReceiptMobileRequest` | `sch:declaracao`, `sch:nif` | receipt/status metadata | read-only receipt lookup | EXACT / HIGH |
| `obterDeclaracaoMobileRequest` | `tns:obterDeclaracaoMobileRequest` | `sch:modelo` containing declaration identifier, taxpayer identifiers and optional SS/IRS Jovem/consignation/IBAN choices | `pdf` | read-only rendered declaration PDF retrieval | EXACT / HIGH |
| `submeterDeclaracaoMobileRequest` | `tns:submeterDeclaracaoMobileRequest` | `sch:modelo` (full declaration graph) | submission metadata | WRITE | HIGH; never live-eligible |

Optionality is confirmed from null guards in the compiled builders. `infoAgregado` serializes nested `UserInfo` objects for the authenticated taxpayer, spouse and zero-or-more dependants. `obterDeclaracao` serializes a Modelo 3 graph already held by the app; it does not return structured prefill data.

## Response and fault handling

The generic parser removes arbitrary SOAP prefixes, selects `Envelope/Body`, then hands the operation payload to a typed parser. Every response uses `statusType/codigo`; non-success status is converted to a sanitized application exception. HTTP/network failures are handled separately. No operation-specific SOAP Fault schema was embedded, so fault detail remains `MEDIUM` rather than guessed.

## Read/write decision

The six `obter`/`info`/`check` call sites only create POST requests and parse responses; no state mutation or submission service is reached. `checkEntregaDeclMobileRequest` is therefore classified read-only from its request builder, result model and consumer. `submeterDeclaracaoMobileRequest` is isolated in `SubmissionService` and remains prohibited.

## Live gate

No live operation is eligible. Request construction is now exact/high and read-only semantics are established, but the official app loads a bundled client identity into a TLS `SecurityContext`. The legitimate Taxy identity has no established DM3IRS entitlement and must not impersonate that channel. Therefore `TAXY_AUTH_PATH_KNOWN = NO`, `networkRequests = 0`, and `writeRequests = 0`.
