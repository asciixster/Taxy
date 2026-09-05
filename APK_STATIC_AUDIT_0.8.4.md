# Taxy 0.8.4 APK static audit

Audit input: the clean CI artifacts from run `33997403975`, built from head
`9c6c1dddd253d644f938339142f23c695e6af458` and the same-run `origin/main`
baseline. Content values were not printed; only sanitized category counts were
used.

## Size

| Artifact | Bytes | MiB |
|---|---:|---:|
| main baseline debug APK | 163,958,140 | 156.36 |
| Taxy 0.8.4 debug APK | 196,987,901 | 187.86 |
| delta | +33,029,761 | +31.50 (+20.15%) |

The increase is dominated by the three bundled ABI variants of the ML Kit OCR
native pipeline and its Dex/model assets. No fiscal-document fixture was added.

## Sanitized scan

| Category | Current | Baseline | Result |
|---|---:|---:|---|
| Private-key PEM marker | 0 | 0 | PASS |
| `.pfx` / `.p12` / `.pkcs12` archive entry | 0 | 0 | PASS |
| `.pem` / `.key` / certificate archive entry | 0 | 0 | PASS |
| Cloudflare token prefix | 0 | 0 | PASS |
| Embedded bearer-token-shaped literal | 0 | 1 | PASS (no new secret; baseline match was non-secret code data) |
| Developer/Codex local path | 0 | 0 | PASS |
| Old `clientes`/`dev` backend hostname | 0 | 0 | PASS |
| Raw PDF/JPEG/PNG under Flutter assets | 0 | 0 | PASS |
| Public `api.taxy.pt` host | 1 file | 1 file | EXPECTED |
| Dormant FactIntWS endpoint | 1 file | 1 file | BASELINE-ONLY, unchanged |
| `localhost` strings | 5 files | 5 files | BASELINE runtime/toolchain strings, unchanged |

The dormant Android FactIntWS research bridge already exists in `main`; this PR
did not add or wire it. The production Flutter application path remains pinned
to `api.taxy.pt` by regression tests. The document-capture path itself contains
no HTTP client or upload operation.

`APK_STATIC_SCAN = PASS`
