# FactIntWS protocol research

## Evidence boundary

Taxy 0.7.4 reconstructed this contract offline from the locally available official e-Fatura APK (version 4.7.1/build 29), its Java call sites, serializers, response DTOs and transport code. These findings are `CONFIRMED_FROM_OFFICIAL_APP`, not official documentation and not runtime confirmation. No FactIntWS request was made.

The APK contains client-certificate, private-key and trust-store assets. Only filenames and code-level roles were inventoried. Their contents were not exported, incorporated, executed, or committed. A future test may use only Taxy's separately legitimate identity.

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

## Runtime boundary

No successful protocol element is marked `RUNTIME_CONFIRMED`. The single request
using the explicit channel reached TLS `secureConnect` but then failed with the
sanitized OpenSSL category `decryption failed or bad record mac`, before HTTP.
This promotes neither the channel nor any submitted SOAP/authentication element.
FactIntWS acceptance of the Taxy username and operation remains unknown.
Fatshare remains unchanged and is not a fallback.
