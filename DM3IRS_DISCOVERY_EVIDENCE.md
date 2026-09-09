# DM3IRS Mobile — evidence ledger

## Evidence levels

| Level | Meaning |
|---|---|
| `APK_STATIC_CONFIRMED` | Confirmed from the user-provided official APK using offline manifest/resource/AOT analysis. |
| `FIXTURE_SHAPE_CONFIRMED` | Field name/type shape confirmed without retaining fixture values. |
| `PUBLIC_XSD_CONFIRMED` | Present in the official Modelo 3 XSD package. |
| `INFERRED` | Plausible but not sufficient for production or live execution. |
| `UNKNOWN` | Evidence absent. |

The APK was held outside the repository and was never executed. Builders, services, parsers, response models, endpoints, namespaces, SOAP actions and the authentication component graph are `APK_STATIC_CONFIRMED`. Field-shape counts are `FIXTURE_SHAPE_CONFIRMED`.

The public 2026 Modelo 3 XSD remains useful for declaration-input structure, but it is not evidence of mobile entitlement and is not a liquidation golden output.

## Runtime evidence acquired later under separate authorization

- the legitimate Taxy mTLS identity was accepted by production TLS;
- catalogs returned business status `0` in a one-shot read;
- corrected `infoUtilizador` framing returned HTTP 200, the exact response root and status `130` without a SOAP Fault;
- offline AOT tracing maps `130`/`131` exactly to the shared `BadIrsYear` effect and an invalid IRS delivery-period message.

No live request was made during the status-code analysis documented at the current head.

## Deliberately unavailable evidence

- contents/private keys/passwords of official PKCS#12 containers;
- official TLS client public certificate fingerprint (container was not opened);
- Taxy entitlement for DM3IRS;
- a successful `infoUtilizador` payload under the legitimate Taxy identity;
- operation-specific fault schema;
- contractual permission to use an official-app-private endpoint in a third-party product.

These gaps explain the zero-request live decision.
