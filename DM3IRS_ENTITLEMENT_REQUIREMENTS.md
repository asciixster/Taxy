# DM3IRS entitlement requirements

## Confirmed technical facts

- SOAP 1.1 service family with production on port 411 and a quality host/port configuration on 711.
- TLS client authentication is used by the official client.
- Taxpayer credentials are protected in a WS-Security UsernameToken-style header with AT-specific encryption/digest handling.
- Six read-only operations and one submission write are statically identified.
- The public AT request-encryption key is common with material already known to Taxy; this is not caller authorization.

## Authorization required from AT

1. Confirmation that third-party integrators may use DM3IRS.
2. Onboarding/homologation procedure and contracting entity requirements.
3. Issuance or allow-listing of a Taxy-controlled client certificate for quality and production.
4. Operation-level scopes restricted to the six read operations; submission excluded.
5. Official endpoint, WSDL/XSD, namespaces, SOAPActions and version lifecycle.
6. Quality test identities/data and rules for synthetic testing.
7. Rate limits, timeout, retry and monitoring policy.
8. Authentication identity rules, sub-user/representative handling and taxpayer consent requirements.
9. Data-processing, storage, audit, breach and retention obligations.
10. Change/deprecation notification and technical support contact.

## Known unknowns

- whether the quality endpoint is accessible to external integrators;
- whether certificates are issued by AT or customer-supplied certificates are allow-listed;
- whether entitlement is per certificate, entity, operation, taxpayer role or environment;
- whether the mobile service family is exclusively reserved for AT applications;
- contractual permission for client-facing prefill, monitoring and official-result comparison;
- official schema version identifiers and compatibility window.

## Minimum requested scope

Request read-only entitlement only for catalogs, authenticated-user information, household information, delivery check, receipt metadata and on-demand declaration retrieval. Explicitly exclude submission and every other state-changing operation.
