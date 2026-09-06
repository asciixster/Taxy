# DM3IRS auth comparison and probe gate

## Offline comparison

| Dimension | Official IRS app path | Legitimate Taxy path | Decision |
|---|---|---|---|
| service | DM3IRS Mobile candidate on port 411 | no DM3IRS binding implemented | not equivalent |
| client certificate role | unknown without APK trace | Taxy client identity has known success only on FactIntWS | entitlement does not transfer |
| auth header | unknown | FactIntWS WS-Security implementation exists | structure cannot be reused by assumption |
| public-key encryption | possible hypothesis only | AT public encryption material is known | fingerprint equality not established |
| channel/app metadata | unknown | no legitimate DM3IRS channel metadata known | must not impersonate official app |
| TLS requirements | endpoint candidate only | Taxy supports modern TLS/mTLS elsewhere | no authorization conclusion |

No official-app private identity, certificate or key was accessed. “Same public key” would prove only the intended AT encryption recipient, never caller authorization.

## Gate evaluation

| Operation | Read-only confirmed | Schema sufficient | Taxy auth available | Deterministic | No side effect confirmed | Eligible |
|---|---:|---:|---:|---:|---:|---:|
| obterCatalogos | NO | NO | NO | NO | NO | NO |
| infoUtilizador | NO | NO | NO | NO | NO | NO |
| infoAgregado | NO | NO | NO | NO | NO | NO |
| checkEntrega | NO | NO | NO | NO | NO | NO |
| obterReceipt | NO | NO | NO | NO | NO | NO |
| obterDeclaracao | NO | NO | NO | NO | NO | NO |

## Next safe evidence acquisition

1. Obtain the official APK/base and splits through a legitimate local source, or a sanitized static-analysis export containing class names, XML constants and call graphs.
2. Recover the exact mobile WSDL/XSD without sending a business request.
3. Prove read-only/no-side-effect semantics per operation.
4. Establish a Taxy entitlement for the service without using official-app private identity or app impersonation.
5. Build a deterministic, sanitized fixture and parser test.
6. Only then issue one request, starting with `obterCatalogosMobileRequest`.

If runtime works but the service remains official-app private, classify it `RUNTIME_TECHNICALLY_AVAILABLE / PRODUCT_USE_REQUIRES_REVIEW`, not production-ready.
