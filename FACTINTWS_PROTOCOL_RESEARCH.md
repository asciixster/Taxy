# FactIntWS protocol research

## Evidence boundary

Taxy 0.7.4 reconstructed this contract offline from the locally available official e-Fatura APK (version 4.7.1/build 29), its Java call sites, serializers, response DTOs and transport code. These findings are `CONFIRMED_FROM_OFFICIAL_APP`, not official documentation and not runtime confirmation. No FactIntWS request was made.

A second static audit on 2026-08-31 used the supplied official public APK
`pt.gov.efatura.mobille.dev.app`, version `6.0.10`, build `20260519`, SHA-256
`964c95c77f5a20dd1e70c6536ce86b163dcdcb0346d319ee50540955375c1173`.
Only the Android manifest, archive inventory and Flutter AOT code snapshot were
examined. This newer, independently built client confirms the same FactIntWS
namespace, ports 443/8443, `EcraInicial` operation and typed XML response path.
The `.dev.app` suffix is the legacy identifier of the package publicly
distributed through Google Play; it is not evidence that this build selects a
quality/development endpoint or identity at runtime.

The APK contains client-certificate, private-key and trust-store assets. Only filenames and code-level roles were inventoried. Their contents were not exported, incorporated, executed, or committed. A future test may use only Taxy's separately legitimate identity.

The 6.0.10 archive likewise contains application-client certificate/key assets.
Their names and the code-level calls to `useCertificateChainBytes` and
`usePrivateKeyBytes` were observed, but those assets were not opened, extracted,
executed or used. The application code also contains a dedicated production AT
encryption public-key asset. This confirms that the official app carries an
application-specific TLS/security context; it does not prove the server's exact
population-selection rule.

## Transport

| Element | Reconstructed value | Evidence |
|---|---|---|
| Primary endpoint | `https://servicos.portaldasfinancas.gov.pt:443/mobile/a4/factintws/ws` | `CONFIRMED_FROM_OFFICIAL_APP` |
| Alternate endpoint | port 8443 at the same path | `CONFIRMED_FROM_OFFICIAL_APP`; no automatic fallback |
| SOAP | 1.1 | `CONFIRMED_FROM_OFFICIAL_APP` |
| Namespace | `http://factemi.at.min_financas.pt/factintws` | `CONFIRMED_FROM_OFFICIAL_APP` |
| Method | `POST` | `CONFIRMED_FROM_OFFICIAL_APP` |
| `SOAPAction` | unquoted `namespace/Operation`, e.g. `.../factintws/EcraInicial` | `CONFIRMED_FROM_OFFICIAL_APP` |
| `Content-Type` | `text/xml;charset=utf-8` | `CONFIRMED_FROM_OFFICIAL_APP` |
| `Accept-Encoding` | `gzip` | `CONFIRMED_FROM_OFFICIAL_APP` |
| User-Agent | `ksoap2-android/2.6.0+` | `CONFIRMED_FROM_OFFICIAL_APP` |
| Timeout | 120000 ms | `CONFIRMED_FROM_OFFICIAL_APP` |
| `Accept`, `Connection` | no custom value found | `UNKNOWN`/platform default |

## Live-preparation gates

The app's `Created` source is an NTP receive timestamp. Taxy's isolated SNTP/NTP
provider performs one UDP exchange, validates the correlated server response and
returns its UTC transmit timestamp. A real one-exchange check against the single
configured server `time.cloudflare.com` succeeded on 2026-08-29. Live use has no
system-clock fallback and no retry.

`CanalOrigem` and its `Sistema`, `Versao` child order are confirmed from the
official app. Its semantics are `RUNTIME_DEVICE_METADATA`: the constructor reads
`android.os.Build.VERSION.SDK_INT` and `android.os.Build.VERSION.RELEASE` each
time it is instantiated. The exact Android value is `Sistema=A`; `Versao` is built as
`Android SDK: <SDK_INT> (<RELEASE>)`. Both facts are
`CONFIRMED_FROM_OFFICIAL_APP`, but the APK contains no fixed runtime SDK/release
pair. The first controlled tooling test therefore used the coherent Android pair
API 35 / Android 15, producing `Android SDK: 35 (15)`. These explicit values are
not promoted to official-app or server-accepted evidence.

The legitimate local `TesteWebservices.pfx` passes the offline preflight: it
opens, contains the private key and three certificates, has a valid chain and TLS
Web Client Authentication EKU, and validates against the local CA material. This
proves local readiness only; it does not prove FactIntWS acceptance.

## Envelope and login flow

The envelope order is `Username`, `Password`, `Nonce`, `Created`. `Security` carries SOAP actor `http://at.pt/actor/SPA`, AT namespace `http://at.pt/wsp/auth`, and `at:Version="2"`. Authentication generates fresh security material for every request. The app's login path submits `EcraInicial` and `DadosContribuinte` as two authenticated calls; it does not establish a reusable SOAP session.

```text
portal password
  + fresh 16-byte AES key
  + NTP-derived UTC Created
        -> encrypted Password / encrypted Digest / RSA-encrypted Nonce
        -> SOAP UsernameToken
        -> operation request
```

The wire operation found for the app concept previously called `ecraInicialF` is `EcraInicial`, with roots `EcraInicialRequest` and `EcraInicialResponse`.

## New-client overview data flow

The 6.0.10 Flutter AOT snapshot contains the concrete generated response parser
`EcraInicialResponse.fromXmlElement` / `_EcraInicialResponseFromXmlElement`, the
`HomeScreenViewModel`, `HomeState.dadosEcraInicial`, the homepage
`_buildBeneficio` widget path and the locale currency formatter. The response
model includes, at minimum:

- `ValorTotalBeneficioProvisorio`;
- `NumTotalFaturasPorValidar`;
- `NumTotalFaturasPorAssociarReceita`;
- `ValorBeneficioProvisorioPorSetor`;
- `ListaSetores`;
- `ValorTotalDespesas` and `ValorTotalIvaDespesas`.

No client-side benefit aggregation, statutory-cap calculation or per-invoice
summation path was found for the homepage total. The observable path is typed
SOAP response -> `EcraInicialResponse` -> homepage state -> currency formatting.
Therefore the official application's provisional benefit is a server-provided
aggregate, not a total that Taxy should reproduce by naively summing document-row
`valorTotalBeneficioProv` values.

The newer app also retains a local active-user model (`SessionViewModel`,
`setCurrentUser`, `UserDTO`) and taxpayer-management UI. That is evidence of a
local selected credential/current-user context, but no additional hidden
taxpayer selector was found in the `EcraInicialRequest` wire contract beyond
`Nif`, `Ano` and `CanalOrigem`.

The public AT request-encryption key in the APK has SPKI SHA-256
`b19983ae125123d3b82afb0845018c2fe4fc8f9556686142b1e371a031a54968`,
an exact match for the key already used by Taxy's controlled connector. The
official production and quality TLS client certificate fingerprints, however,
match neither Taxy's local nor backend client identity. This rejects an AT
cipher-key mismatch and records the application TLS identity as the strongest
concrete remaining population-context difference. Full evidence and safety
boundaries are in `OFFICIAL_EFATURA_APK_6_0_10_AUDIT.md`.

## Runtime boundary

No successful protocol element is marked `RUNTIME_CONFIRMED`. The single request
using the explicit channel reached TLS `secureConnect` but then failed with the
sanitized OpenSSL category `decryption failed or bad record mac`, before HTTP.
This promotes neither the channel nor any submitted SOAP/authentication element.
FactIntWS acceptance of the Taxy username and operation remains unknown.
Fatshare remains unchanged and is not a fallback.

A subsequent single-variable TLS 1.2-only request failed earlier, with TLS alert
40 during the handshake and before `secureConnect`. It produced no HTTP or SOAP
evidence and did not promote TLS 1.2, the operation, or any authentication field
to runtime-confirmed status.

The next single-variable experiment restored the original TLS negotiation and
changed only the endpoint to the official-app port 8443. It negotiated authorized
TLS 1.3 with `TLS_AES_128_GCM_SHA256`, returned HTTP 200 and a functional
`EcraInicialResponse` without SOAP fault. Port 8443 and the concrete submitted
read-only contract are therefore `RUNTIME_CONFIRMED` for this request.
