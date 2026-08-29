# FactIntWS protocol research

## Evidence boundary

This document records an offline reconstruction for Taxy 0.7.4. No FactIntWS request was made. Every observation from the historical official e-Fatura application is labelled `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP`; it is not official protocol documentation and is not runtime confirmation.

Taxy must never use certificates, private keys, PKCS#8 material, PFX files, or any cryptographic identity extracted from the official application. The only planned client identity is the separately and legitimately available `TesteWebservices.pfx`, kept outside Git.

## Structural evidence

| Element | Value | Evidence |
|---|---|---|
| Primary endpoint | `https://servicos.portaldasfinancas.gov.pt:443/mobile/a4/factintws/ws` | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP` |
| Alternate endpoint | `https://servicos.portaldasfinancas.gov.pt:8443/mobile/a4/factintws/ws` | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP`; not selected and no fallback permitted |
| SOAP version | SOAP 1.1 | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP` |
| Service namespace | `http://factemi.at.min_financas.pt/factintws` | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP` |
| WS-Security namespace | `http://schemas.xmlsoap.org/ws/2002/12/secext` | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP` |
| AT authentication namespace | `http://at.pt/wsp/auth` | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP` |
| Actor | `http://at.pt/actor/SPA` | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP` |
| Security fields | `UsernameToken`, `Username`, password digest, `Nonce`, `Created` | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP` |
| Candidate operation | `ecraInicialF` | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP` |

## Sanitized structural representation

This is a research representation, not a sendable request. Unknown XML names and bodies remain explicit placeholders.

```xml
<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/"
            xmlns:wss="http://schemas.xmlsoap.org/ws/2002/12/secext"
            xmlns:at="http://at.pt/wsp/auth"
            xmlns:app="http://factemi.at.min_financas.pt/factintws">
  <S:Header>
    <wss:Security S:actor="http://at.pt/actor/SPA">
      <wss:UsernameToken>
        <wss:Username>[REDACTED_USERNAME]</wss:Username>
        <wss:Password Digest="[UNKNOWN_DIGEST_ATTRIBUTE]">[REDACTED]</wss:Password>
        <wss:Nonce>[REDACTED]</wss:Nonce>
        <wss:Created>[REDACTED]</wss:Created>
      </wss:UsernameToken>
    </wss:Security>
  </S:Header>
  <S:Body>
    <app:[UNKNOWN_ECRAINICIALF_ROOT]>
      [UNKNOWN_REQUIRED_BODY]
    </app:[UNKNOWN_ECRAINICIALF_ROOT]>
  </S:Body>
</S:Envelope>
```

## `ecraInicialF` schema

The operation name is historical evidence, but no local WSDL/XSD, decompiled method body, request DTO, serializer, fixture, or sanitized request was found that demonstrates:

- the exact root element (`ecraInicialF`, `EcraInicialFRequest`, or another name);
- whether the operation is document/literal or wrapped;
- mandatory child elements;
- element order, qualification, or nullability;
- SOAPAction behavior.

Status: `FACTINTWS_OPERATION_SCHEMA_UNKNOWN`.

## TLS identity

`TesteWebservices.pfx` is the sole planned identity because it is legitimately available and previously worked with fatshare. FactIntWS acceptance is `UNKNOWN`: no handshake was attempted in 0.7.4 because the SOAP authentication and operation schema gates failed first. The alternate port, another PFX, and official-app identity material were not attempted.

## Separation from fatshare

FactIntWS is a separate research module. The existing fatshare endpoint, namespace, serializer, authentication, evidence, and parser remain unchanged. No fallback exists between the protocols.
