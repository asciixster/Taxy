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

No element is marked `RUNTIME_CONFIRMED`. FactIntWS acceptance of `TesteWebservices.pfx`, the Taxy username, the reconstructed authentication fields, and any operation remains unknown until a separately approved single request. Fatshare remains unchanged and is not a fallback.
