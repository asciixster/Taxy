# Portal IRS prefill — sanitized runtime evidence

Date: 2026-09-19

## Result

The legitimate taxpayer-authenticated Portal flow loaded the official 2025
prefilled declaration successfully in a real Chromium session.

- Source: `irs.portaldasfinancas.gov.pt/app/entrega/v2026`
- Operation: official read-only prefill flow
- Authentication: taxpayer credentials supplied at runtime; never logged or stored
- Annexes observed: A, C, H
- Household structure present: yes
- Category A structure present: yes
- Category B structure present: yes
- Scalar fields observed: 180
- Populated scalar fields observed: 177
- Table rows observed: 71
- AT write operations: 0
- Raw fiscal payload persisted: no

Counts describe the in-memory Angular model shape only. No taxpayer identifiers,
amounts, credentials, cookies, tokens, or raw responses are included here.

## Product conclusion

Connector-first automation is technically viable for the central IRS use case.
Production integration still requires a backend session boundary, strict field
normalization, explicit user confirmation, fail-closed parsing, and regression
tests. This evidence does not authorize submission or any other AT write.
