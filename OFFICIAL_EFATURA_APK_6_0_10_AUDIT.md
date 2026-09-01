# Official e-Fatura APK 6.0.10 audit

## Scope and safety boundary

This is an offline static audit of the user-supplied APK. No AT request was
made, the APK was not installed or executed, and no operation capable of
changing taxpayer data was invoked.

The archive contains private application key material. That material was not
opened, exported, copied out of the APK, executed, incorporated into Taxy or
used for authentication. Public X.509 certificates and the public AT RSA
encryption key were inspected only to identify their role and compare public
fingerprints. All conclusions below preserve that boundary.

## APK provenance

| Element | Observation | Evidence level |
|---|---|---|
| Package | `pt.gov.efatura.mobille.dev.app` | Direct APK manifest evidence |
| Version | `6.0.10` | Direct APK manifest evidence |
| Build | `20260519` | Direct APK manifest evidence |
| APK SHA-256 | `964c95c77f5a20dd1e70c6536ce86b163dcdcb0346d319ee50540955375c1173` | Direct file evidence |
| Distribution | Same package is the public Google Play e-Fatura application | Public store evidence |
| Build mode | Flutter AOT product snapshot | Direct native-library evidence |
| Flutter engine | engine revision `42d3d75a56efe1a2e9902f52dc8006099c45d937` | Direct native-library evidence |

The legacy `.dev.app` suffix in the package identifier is not evidence that
this APK uses the quality environment at runtime. It is the package currently
distributed to the public as e-Fatura. Runtime environment selection must be
established from code/configuration evidence, not inferred from the identifier.

## FactIntWS environment and transport evidence

The Flutter AOT snapshot directly contains both FactIntWS endpoints, the SOAP
namespace and the operation/request infrastructure:

- `https://servicos.portaldasfinancas.gov.pt:443/mobile/a4/factintws/ws`;
- `https://servicos.portaldasfinancas.gov.pt:8443/mobile/a4/factintws/ws`;
- `http://factemi.at.min_financas.pt/factintws`;
- SOAP 1.1 envelope construction;
- unquoted `SOAPAction` in the form `namespace/Operation`;
- WS-Security actor `http://at.pt/actor/SPA` and AT security version `2`;
- `Username`, encrypted `Password`, encrypted `Digest`, encrypted `Nonce` and
  `Created` handling;
- `Dart HttpClient`, gzip response handling and a custom `SecurityContext`.

The same snapshot references configuration properties named
`clientCertificateFilename`, `clientKeyFileName`,
`serverCaCertificateFilename`, `endpoint`, `AppEnvironment` and
`getEndpointsForSelection`. It also directly references the following assets:

- `assets/prod_client.cer`;
- `assets/prod_client_password.pkcs8`;
- `assets/qua_client.cer`;
- `assets/qua_client_password.pkcs8`;
- `assets/master-cacert.pem`;
- `assets/sapubkey20250620.prod.pem`.

Calls to `useCertificateChainBytes`, `usePrivateKeyBytes`,
`setTrustedCertificatesBytes` and `SecurityContext_TrustBuiltinRoots` confirm
that these filenames participate in environment-driven TLS configuration. This
does not authorize Taxy to use the app's private material.

## Public cryptographic material

Only public certificates/keys were parsed. Fingerprints are recorded to make
the comparison reproducible without retaining private material.

| Material | Certificate SHA-256 | SPKI SHA-256 | Public key | Validity | Role supported by evidence |
|---|---|---|---|---|---|
| Official app `prod_client.cer` | `e541fdb09954f70d1098a1194df7986b243b2f9c8f699f94b5d7011ebff6fead` | `453bfee2926e79aa4fd7087cdafaf1701280374c604ccaa5fdeafdf9aecbfc78` | RSA 4096, e=65537 | 2024-12-12 to 2026-12-12 | TLS client authentication; production-labelled app identity |
| Official app `qua_client.cer` | `fd243983d432681820bd494d03c14e094fc3c89d16e390141feb585d92788bd5` | `d2214d160dc71621bd683f888c9af2439c26bd63c476c87f2d838a466699e2e3` | RSA 4096, e=65537 | 2026-01-19 to 2026-07-18 | TLS client authentication; quality/test-labelled app identity |
| Taxy local legitimate identity used in the controlled FactIntWS path | `8c274b8bbebdfd5f86bd55e132897a87a44357b6b892e0697c362e0ecab88807` | deliberately not expanded here | RSA client identity | valid at the controlled test | Taxy TLS client authentication |
| Taxy backend legitimate identity | `d9b103a05e5ac296b9563fa2f16006fb9e15bae33fb2d8a6d16a5324da43fb09` | `ddf1aa8e23a2187972a78b8dbaa856751330706a405eabcff06584a2d25eb306` | RSA client identity | 2026-08-05 to 2028-08-04 | Taxy backend TLS client authentication |

Both official public client certificates carry the TLS Web Client
Authentication EKU. Neither Taxy certificate fingerprint matches either
official-app client certificate. The comparison establishes different client
identities; it does not expose or use any official-app private key.

The official APK's public AT request-encryption key has:

- file SHA-256
  `32e2cc329cb48ceb5e33b534576b01667d47b2dbf35ae77dcbc9809658f40f5f`;
- SPKI SHA-256
  `b19983ae125123d3b82afb0845018c2fe4fc8f9556686142b1e371a031a54968`;
- RSA 4096, exponent 65537.

That SPKI fingerprint is an exact match for the public AT cipher key already
used by Taxy's controlled connector. `AT_CIPHER_PUBLIC_KEY_MISMATCH` is therefore
rejected for the compared paths.

## Production-environment inference

The following are direct observations:

1. the APK is the publicly distributed e-Fatura application;
2. its code references distinct production and quality client identities;
3. its code references the production-labelled AT public cipher key;
4. the quality client certificate expired on 2026-07-18;
5. the public application was observed functioning after that date.

It is therefore a high-confidence inference, not a captured runtime trace, that
the public application selects the production identity/configuration (or an
equivalent renewed production path) for normal public operation. The exact
branch selected at runtime remains unproven by static analysis alone.

## Overview and population data flow

The AOT snapshot contains the generated parser
`EcraInicialResponse.fromXmlElement`, the generated response model,
`HomeScreenViewModel`, `HomeState.dadosEcraInicial`, the homepage
`_buildBeneficio` path and locale-aware currency formatting. The response model
contains at least:

- `ValorTotalBeneficioProvisorio`;
- `NumTotalFaturasPorValidar`;
- `NumTotalFaturasPorAssociarReceita`;
- `ValorBeneficioProvisorioPorSetor`;
- `ListaSetores`;
- `ValorTotalDespesas`;
- `ValorTotalIvaDespesas`.

The observed client path is:

```text
FactIntWS EcraInicialResponse
  -> generated typed XML parser
  -> HomeState.dadosEcraInicial
  -> homepage benefit/count/sector widgets
  -> locale-aware display formatting
```

No app-side algorithm was found that recomputes the homepage provisional
benefit by summing invoice rows or applying statutory caps. Consequently, the
official value is a consolidated server-provided FactIntWS aggregate. The
personal Portal IRS-document rows are useful invoice inputs but are not an
equivalent aggregate contract.

## Credential and selected-taxpayer flow

The app contains `SessionViewModel`, `setCurrentUser`, `UserDTO`, a list of
stored users, an `isSelecionado` state and taxpayer-management/home-screen
components. This supports the following local flow:

```text
stored credential list
  -> active credential/current user
  -> selected taxpayer context
  -> SOAP_USERNAME = complete login identity
  -> request Nif = selected/base taxpayer identity
  -> EcraInicial / pending / sector operations
```

No additional hidden `EcraInicialRequest` population selector was found beyond
`Nif`, `Ano` and `CanalOrigem`. No server-side selected-taxpayer activation
operation or mandatory session cookie was found. Equality of the base taxpayer
identifier between Taxy and the visual official-app observation has already
been safely confirmed. Equality of the complete login/subuser identity remains
`UNKNOWN` because it must not be printed or inferred from the base identifier.

## Taxy versus official application

| Layer | Result | Interpretation |
|---|---|---|
| Endpoint/port | Match for the confirmed `:8443` path | Not the population differentiator |
| SOAP envelope/action/body schema | Match | No structural population field is missing |
| Digest/password/nonce/Created | Reconstructed and runtime accepted | Authentication succeeds, but population equivalence is not proved |
| AT public cipher key | Exact SPKI match | Cipher-key mismatch rejected |
| Base taxpayer identity | Confirmed equal | Base-NIF mismatch rejected |
| Year | Same explicit 2026 comparison | Year mismatch low/rejected for this observation |
| Client TLS identity | Different | Concrete application-context difference |
| Complete login/subuser identity | Unknown equality | Secondary unresolved logical-context difference |
| Overview parser | Synthetic non-zero contract passes; unsafe zero defaults fixed | Parser data loss is not the leading cause |
| Direct pending/all-sector probes | Both returned controlled empty results under Taxy identity | Divergence is broader than one overview field |

## Ranked explanation of the zero population

1. **`CLIENT_APPLICATION_IDENTITY_CONTEXT_MISMATCH` — HIGH.** The client
   identities are demonstrably different. Taxy's certificate can be accepted
   for mTLS and yield HTTP 200/business status while the service still applies
   a different application entitlement or population policy. Static client
   evidence cannot prove the server rule, but this is the strongest concrete
   difference left.
2. **`LOGIN_IDENTITY_LOGICAL_CONTEXT_MISMATCH` — MEDIUM.** Base taxpayer
   equality is known, complete credential/subuser equality is not. A different
   complete login can select different authorizations even with the same base
   taxpayer identifier.
3. **`UNKNOWN_SERVER_POPULATION_RULE` — MEDIUM.** The server may combine the
   client identity, credential class and operation authorization in a rule not
   represented in the SOAP body. This is a description of the remaining server
   boundary, not a separate protocol field discovered in the APK.

The following hypotheses are now low or rejected: request encryption public
key, base taxpayer, year, `CanalOrigem`, SOAP schema, response parser, bootstrap
cookie and ordinary HTTP framing.

## Engineering conclusion

The APK analysis does not reveal a missing calculation that Taxy can safely
copy. It instead confirms that the official value is returned by FactIntWS and
that the official application uses a distinct, provisioned TLS application
identity. Taxy must not use that private identity.

For a production backend, the supported paths are therefore:

1. obtain an AT-authorized FactIntWS client identity/entitlement for Taxy that
   is explicitly permitted to access the consumer population; or
2. use a separate officially supported personal-data source and expose only
   fields whose semantics are demonstrated, leaving the provisional benefit
   unavailable until AT provides the consolidated aggregate.

The existing backend behavior is correct to expose unavailable aggregates as
`unavailable`, not as zero and not as a naive sum of Portal document rows.
