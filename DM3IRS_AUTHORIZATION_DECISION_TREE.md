# DM3IRS authorization decision tree

```text
AT response
├─ AUTHORIZED
│  ├─ record written scope, operations, certificate and environments
│  ├─ complete privacy/terms review
│  └─ execute quality probe plan; production remains blocked
├─ QUALITY_ONLY
│  ├─ provision quality certificate/test identity
│  ├─ execute one request per approved step
│  └─ submit evidence for production homologation
├─ NEEDS_HOMOLOGATION
│  ├─ obtain checklist/WSDL/XSD/test cases
│  ├─ prepare security, privacy, consent and retention dossier
│  └─ test only within the authorized homologation environment
├─ NOT_AVAILABLE_TO_THIRD_PARTIES
│  ├─ stop the DM3IRS product path
│  ├─ retain research documentation only
│  └─ use the documented Taxy fallback
└─ UNKNOWN / PARTIAL ANSWER
   ├─ ask for operation-level and certificate-level clarification
   ├─ do not probe
   └─ escalate to the named AT technical/security contact
```

An HTTP/TLS response obtained without explicit entitlement would not replace an `AUTHORIZED` decision. Authorization evidence must identify the entity, environment, certificate role, permitted operations and applicable terms.
