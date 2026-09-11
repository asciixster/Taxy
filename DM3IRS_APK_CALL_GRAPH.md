# DM3IRS APK call graph

## Shared transport

`screen/view-model -> domain service -> RequestDataBuilder -> ApiService.performRequest -> ApiHttpService (TLS/mTLS) -> SOAP parser -> typed model -> view-model/screen`

`ApiService` constructs the SOAP 1.1 envelope, WS-Security header and request root. `ApiAuthenticationService` constructs one authentication header per taxpayer represented in a household request.

## Operations

| Operation | Builder | Service | Parser/model | Principal consumer |
|---|---|---|---|---|
| infoUtilizador | `UserInfoRequestBuilder` | `UserInfoService.fetchUserInformation` | `AuthUserInformation.fromResponse` | login/profile/home initialization |
| infoAgregado | `FamilyCompositionRequestBuilder` | `FamilyCompositionService` | `AuthUserInformation.fromResponse` | family composition, income, expenses, pre-liquidation and liquidation views |
| obterCatalogos | `EntityRequestBuilder` | `EntityService.loadAllEntities` | `CatalogsData.fromResponse` | bank, consignation, institution and expense-chart lookups |
| checkEntrega | `DeclarationRequestBuilder` | `DeclarationService` | `DeliveredDeclaration.fromResponse` | Home/delivery availability flow |
| obterReceipt | `DeclarationReceiptRequestBuilder` | `DeclarationService.fetchDeclarationReceiptWithId` | `DeclarationReceipt.fromResponse` | receipt/status screen |
| obterDeclaracao | `PdfReceiptRequestBuilder` | `DeclarationService.fetchPdfReceipt` | `PdfReceipt.fromResponse` | declaration PDF viewer/share flow |
| submeterDeclaracao | `SubmitDeclarationRequestBuilder` | `SubmissionService` | submission response model | confirmation/submission flow (WRITE; not executed) |

For infoUser specifically, the caller chain is `AuthenticationService.navigateAfterDelivery -> AuthenticationService.getPostLoginNavigation -> UserInfoService.fetchUserInformation(year, baseNif) -> UserInfoRequestBuilder.addBody`. The official call-site supplies both values; the builder emits `ano-fiscal` before `nif` and only omits an element when the corresponding map value is null.

## Important semantic finding

`infoAgregado`, not `obterDeclaracao`, is the source consumed by the income, expenses, pre-liquidation and liquidation demonstration screens. `obterDeclaracao` serializes an already prepared Modelo 3 model and retrieves a PDF representation.
