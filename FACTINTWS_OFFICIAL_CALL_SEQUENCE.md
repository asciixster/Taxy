# FactIntWS official call sequence

Offline reconstruction from the official e-Fatura Android app v4.7.1 (build
29). This audit used symbolic identities only, did not access password values
and made no network request.

## Launcher and authentication

| Order | Trigger | Operation | Request identity | Response use | State created | Evidence |
|---:|---|---|---|---|---|---|
| 0 | Launcher creation | none | `LOGIN_IDENTITY` is placed in `AppStateContainer.numeroFiscal` and in `CommunicationInfo` | none | current local credential | `CONFIRMED_FROM_OFFICIAL_APP` |
| 1 | Login button / restored credential | `EcraInicial` | full `LOGIN_IDENTITY` in WS-Security; `BASE_NIF` in body; current civil year | validates operation and supplies overview DTO | no explicit remote-session token; response retained only for login success processing | `CONFIRMED_FROM_OFFICIAL_APP` |
| 2 | Same `autenticar()` task | `DadosContribuinte` | same full WS-Security identity; same `BASE_NIF` in body | reads `Nif`, `Nome`, `WSResult`; constructs local `User`/display name | local authenticated-user cache | `CONFIRMED_FROM_OFFICIAL_APP` |
| 3 | Authentication callback | none | current complete credential remains selected | opens homepage | selected credential and display name in local state | `CONFIRMED_FROM_OFFICIAL_APP` |

`AplicacaoWSManager.autenticar()` creates the first two request objects in an
array. `WsCallerAsyncTask` executes that array sequentially: the first
`EcraInicial` precedes `DadosContribuinte`.

`DadosContribuinte` is therefore not a prerequisite for the first successful
`EcraInicial`. Its response DTO contains only taxpayer identity/profile fields
and `WSResult`; no token, session identifier, population selector or value
copied into later requests was found.

## Homepage sequence

After authentication, `HomepageActivity.onCreate()` calls
`obtemEcraInicial(SELECTED_TAXPAYER, selectedYear)`. That manager method creates
and sequentially executes:

| Order | Operation | Material request fields | State consumed later |
|---:|---|---|---|
| 1 | `EcraInicial` | `Nif`, `Ano`, `CanalOrigem` | overview values, capability flags and sector aggregates rendered by the homepage |
| 2 | `FaturasPorSetor` aggregate | `NifAdquirente`, explicit empty `CodSetor`, `Ano`, `Indice=0`, `CanalOrigem` | total-expenses homepage card |
| 3 | `CarteiraIncentivo` | `Nif`, `Ano`, `CanalOrigem` | separate incentive card |

The overview visible in the official homepage is therefore a second
`EcraInicial`, after the login pair `EcraInicial -> DadosContribuinte`.

Pending and concrete-sector calls are later and conditional:

```text
NumTotalFaturasPorValidar > 0
  -> user opens validation screen
  -> FaturasPorClassificar(BASE_NIF, selected year)

user opens one sector
  -> FaturasPorSetor(BASE_NIF, sector code, selected year, offset)
```

## Selected taxpayer

The selected taxpayer is local credential state. Choosing another saved user
updates all of:

- `AppStateContainer.numeroFiscal`;
- the current WS-Security credential;
- the NIF from which operation body values are derived.

No operation that activates a body-only taxpayer on the server was found. The
official selector switches a complete credential, not an independent household
member parameter.

## Taxy comparison

The controlled Taxy tooling executes one requested operation at a time. Its
successful overview call did not first reproduce the official login sequence
`EcraInicial -> DadosContribuinte`, and it did not then issue the homepage
`EcraInicial` as a second call.

This is a concrete call-order difference. A server-side bootstrap effect is
still `INFERENCE`, not demonstrated: the official client exposes no token and
does not intentionally carry cookies or a connection across those operations.

## Next sequence candidate

If a future controlled test targets call order, reproduce exactly:

```text
EcraInicial(authentication year)
  -> DadosContribuinte
  -> EcraInicial(2026)
```

Keep the credential identity, body NIF derivation, endpoint, TLS identity,
channel and crypto unchanged. Evaluate only the final overview. This is a
single call-sequence experiment, not three parameter experiments.
