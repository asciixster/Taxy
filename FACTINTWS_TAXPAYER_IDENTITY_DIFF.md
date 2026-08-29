# FactIntWS taxpayer identity difference audit

This is an offline, sanitized audit. It uses symbolic identities only and
made no request to the AT. The user-supplied visual observation from the
official app is recorded as `USER_CONFIRMED_OFFICIAL_APP_VISUAL_EVIDENCE`; no
screenshot or personal value is stored in the repository.

## Identity vocabulary

- `LOGIN_ID`: the complete Portal das Financas username used for
  authentication. It can be a primary nine-digit username or the historically
  supported `BASE_NIF/subuser` form.
- `BASE_NIF`: the first nine characters of `LOGIN_ID`.
- `SELECTED_NIF`: the username of the complete credential currently selected
  in the official app. It is not proven to be an independently selectable
  household-member identifier.
- `REQUEST_NIF`: the nine-digit value serialized in an operation body.

No real value is needed to establish the transformations below.

## Official-app flow

The official Android app v4.7.1 (build 29) establishes the following flow:

```text
AUTHENTICATED_USER credential (LOGIN_ID + password)
  -> AppStateContainer.numeroFiscal
  -> current credential selected in HomepageActivity (SELECTED_NIF)
  -> AplicacaoWSManager.setCredencial(SELECTED_NIF, selected password)
  -> WS-Security Username = complete SELECTED_NIF
  -> getNifPrincipal(SELECTED_NIF) = first nine characters
  -> EcraInicial.Nif = REQUEST_NIF
  -> FaturasPorClassificar.Nif = REQUEST_NIF
  -> FaturasPorSetor.NifAdquirente = REQUEST_NIF
```

Direct evidence:

- `BaseAppStateContainer.getNumeroFiscalPrincipal()` returns the first nine
  characters of the current username.
- `AplicacaoWSManager.getNifPrincipal()` preserves a value of at most nine
  characters and truncates a longer username to its first nine characters.
- `WSManager.setCredencial()` stores the complete selected username in
  `CommunicationInfo`; `WsCallerAsyncTask` passes that value to
  `WsSecurityManager`, whose username is serialized in `wss:Username`.
- `AplicacaoWSManager` applies `getNifPrincipal()` before adding `app:Nif` or
  `app:NifAdquirente` to every audited read request.
- `HomepageActivity.onIconUsersClick()` selects a complete saved `Credencial`,
  updates `AppStateContainer.numeroFiscal`, and calls `setCredencial()` with
  that credential's username and password before refreshing the homepage.

The official selector therefore switches authenticated credentials. Local
evidence does **not** show one authenticated principal querying an arbitrary
dependent merely by changing a body NIF. A selected username may differ from
the credential used when the app session first opened, but after selection it
also becomes the active authentication identity.

## Taxy flows

### Reference/Node connector used by the controlled requests

```text
AT_USERNAME = LOGIN_ID
  -> WS-Security Username = complete LOGIN_ID
  -> username.split('/')[0] = BASE_NIF
  -> EcraInicial.Nif = BASE_NIF
  -> FaturasPorClassificar.Nif = BASE_NIF
  -> FaturasPorSetor.NifAdquirente = BASE_NIF
```

This transformation is structurally equivalent to the official app for a
given active credential. The connector has no separate selected-credential
state: `SELECTED_NIF` is always derived from `LOGIN_ID`.

### Android runtime bridge

The Android bridge currently accepts and stores only a primary nine-digit NIF.
The same stored value is used for `wss:Username`, `EcraInicial.Nif`,
`FaturasPorClassificar.Nif`, and `FaturasPorSetor.NifAdquirente`.

```text
LOGIN_ID = BASE_NIF = SELECTED_NIF = REQUEST_NIF
```

It therefore has neither subuser representation nor an independent selected
credential. This audit does not alter that bridge.

## Sanitized EcraInicial comparison

Both builders serialize the same root, namespace, child order and non-identity
fields:

```xml
<app:EcraInicialRequest xmlns:app="http://factemi.at.min_financas.pt/factintws">
  <app:Nif>&lt;REQUEST_NIF&gt;</app:Nif>
  <app:Ano>2026</app:Ano>
  <app:CanalOrigem>
    <app:Sistema>A</app:Sistema>
    <app:Versao>Android SDK: 35 (15)</app:Versao>
  </app:CanalOrigem>
</app:EcraInicialRequest>
```

No difference was found in root, namespace, order, encoding, empty/nil
handling, or whitespace with material XML semantics. The unresolved comparison
is the value identity relationship:

```text
OFFICIAL REQUEST_NIF = BASE_NIF(official SELECTED_NIF)
TAXY REQUEST_NIF     = BASE_NIF(configured LOGIN_ID)
```

The repository and the supplied visual evidence do not establish that these
two sanitized values are equal. That equality must be checked locally without
printing either value.

## Runtime interpretation

Successful mTLS, WS-Security authentication, HTTP 200 and business code 200
prove transport and authentication acceptance. They do not prove that the
body requested the intended taxpayer population.

For the same intended account and year, the official app visibly reports five
pending invoices, a non-zero provisional benefit and non-zero sectors, while
the Taxy overview reports zeros. This rejects `GENUINE_OPERATION_EMPTY` for
`EcraInicial` and `FaturasPorClassificar` **if** the compared selected identity
is the same. The divergence already exists in `EcraInicial`, so changing the
pending request in isolation is not justified.

## Hypothesis ranking

| Hypothesis | Confidence | Evidence for | Evidence against / falsifier |
|---|---|---|---|
| `TAXPAYER_SELECTION_MISMATCH` | **HIGH** | Official app can select a different complete credential; Taxy has no selected-credential state; observed populations diverge at `EcraInicial` | Falsified by a local equality check proving `BASE_NIF(official selected credential) == BASE_NIF(Taxy LOGIN_ID)` |
| `LOGIN_VS_SELECTED_NIF_MISMATCH` | **MEDIUM** | Taxy's selected population is implicitly derived from configured login, whereas the official app explicitly tracks the selected credential | The official app does not show a body-only taxpayer override; selecting a user also changes authentication credentials |
| `UNKNOWN_SERVER_POPULATION_RULE` | **MEDIUM** | Authentication success is not a guarantee of population equivalence, and server authorization/population rules are undocumented | Becomes less likely if an identity-matched EcraInicial reproduces the official non-zero overview |
| `SUBUSER_IDENTITY_MISMATCH` | **LOW-MEDIUM** | Official and Node flows allow a full subuser login with a base-NIF body; Android runtime does not | For a primary login the transformation is identical; no evidence says the visual session used a subuser |
| `REQUEST_NIF_SERIALIZATION_MISMATCH` | **LOW** | A wrong runtime value remains possible | XML structure and base-NIF transformation match the official builder exactly |
| `CANALORIGEM_MISMATCH` | **LOW** | Server population semantics are not formally documented | The value was accepted at runtime and no identity-specific branch was found |
| `YEAR_MISMATCH` | **LOW** | Business rules around year transitions exist | Both observations explicitly concern 2026 |

## CodSetor scope

The explicit empty `CodSetor` used by the official homepage remains a relevant
future difference for an all-sector `FaturasPorSetor` request. It cannot
explain the incorrect `EcraInicial` aggregates or pending count because
`EcraInicial` has no `CodSetor` field.

## Recommended single-variable experiment

First perform a zero-network equality gate between the base NIF of the
credential selected in the official app and the base NIF of Taxy's configured
login, reporting only `EQUAL` or `DIFFERENT`.

If they are `DIFFERENT`, execute one `EcraInicial` call changing only the
logical `LOGIN_IDENTITY` to the exact complete credential selected in the
official app. Keep year 2026, endpoint, TLS identity, channel, crypto and all
serialization unchanged; continue deriving `REQUEST_NIF` from that login in
the existing way. This mirrors the official flow more faithfully than a
body-only NIF override. If the identities are already `EQUAL`, do not spend a
request on this hypothesis; it is falsified and the next investigation target
is `UNKNOWN_SERVER_POPULATION_RULE`.
