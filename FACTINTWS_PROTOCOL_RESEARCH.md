# FactIntWS protocol research

## Evidence status

`HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP`

This document records offline historical observations supplied for research. It is **not** official protocol documentation and none of the values below is promoted to `RUNTIME_BEHAVIOR_CONFIRMED`. No FactIntWS network request was made as part of Taxy 0.7.3.

## Observed historical contract

| Field | Historical observation | Runtime status |
|---|---|---|
| Test/alternate endpoint | `https://servicos.portaldasfinancas.gov.pt:8443/mobile/a4/factintws/ws` | `NOT_TESTED` |
| Port 443 endpoint | `https://servicos.portaldasfinancas.gov.pt:443/mobile/a4/factintws/ws` | `NOT_TESTED` |
| SOAP version | SOAP 1.1 | `NOT_TESTED` |
| Service namespace | `http://factemi.at.min_financas.pt/factintws` | `NOT_TESTED` |
| WS-Security namespace | `http://schemas.xmlsoap.org/ws/2002/12/secext` | `NOT_TESTED` |
| AT authentication namespace | `http://at.pt/wsp/auth` | `NOT_TESTED` |
| SOAP actor | `http://at.pt/actor/SPA` | `NOT_TESTED` |
| UsernameToken fields | `Username`, password digest, `Nonce`, `Created` | `NOT_TESTED` |

## Safety boundary

- FactIntWS is research-only in this release and has no live client or fallback path.
- Taxy does not use certificates, private keys, PKCS#8 material, PFX files or any other cryptographic identity extracted from the official application.
- The only client identity permitted for Taxy live work is the separately and legitimately supplied `taxy-at-client.pfx`, kept outside Git.
- Historical observations do not authorize endpoint probing or protocol experimentation.
- The confirmed fatshare `InvoicesRequest` implementation remains isolated and unchanged.
