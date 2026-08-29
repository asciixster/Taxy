# FactIntWS password digest research

## Result

`FACTINTWS_DIGEST_NOT_READY`

Offline searches of the available extracted/documented material found the structural names `Password Digest`, `Nonce`, `Created`, and a reference to `buildPasswordDigest`, but did not locate the function body or an independently verifiable test vector. The WS-Security field names alone do not prove the digest formula.

## Evidence matrix

| Detail | Finding | Evidence |
|---|---|---|
| Password is represented by a digest | Observed structurally | `HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP` |
| Hash algorithm is SHA-1 | Mentioned in research target, but no implementation/test vector was located | `UNKNOWN` |
| Digest inputs | Password, nonce, and Created appear related | `INFERENCE`; exact set is `UNKNOWN` |
| Input order | Not demonstrated | `UNKNOWN` |
| Password treatment | Raw bytes, text, prior hash, or another transformation not demonstrated | `UNKNOWN` |
| Character encoding | Not demonstrated | `UNKNOWN` |
| Base64 stage | Digest value appears encoded, but the encoded bytes/stage are not demonstrated | `UNKNOWN` |
| Digest XML attribute/type | Exact name and value not demonstrated | `UNKNOWN` |

The standard WS-Security expression commonly associated with password digests was deliberately **not** assumed. FactIntWS may use standard behavior, an AT-specific variant, or app-specific preprocessing; selecting one without the historical implementation or official documentation would be protocol invention.

## Nonce

| Detail | Status |
|---|---|
| Cryptographically random generation | `UNKNOWN` |
| Byte length | `UNKNOWN` |
| Raw bytes versus text before hashing | `UNKNOWN` |
| XML Base64 encoding | `UNKNOWN` |
| Encoding/type attribute | `UNKNOWN` |

## Created

| Detail | Status |
|---|---|
| UTC versus local time | `UNKNOWN` |
| Exact ISO-8601 layout | `UNKNOWN` |
| Fractional-second precision | `UNKNOWN` |
| Trailing `Z` or offset | `UNKNOWN` |
| Same text/bytes used by digest and XML | `UNKNOWN` |

The runtime-confirmed fatshare timestamp format was not reused because FactIntWS is a separate protocol.

## Evidence required to proceed

Any one of the following could make reconstruction reviewable:

1. the historical `buildPasswordDigest` implementation plus its callers;
2. official FactIntWS authentication documentation;
3. a sanitized deterministic test vector specifying password bytes, nonce bytes, Created bytes, digest bytes, and XML representation.

Until then, Taxy refuses to build or send a FactIntWS authentication header.
