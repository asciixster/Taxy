# FactIntWS password digest research

## Result

`EXACT` from the official app implementation, with deterministic synthetic regression vectors. This is still `CONFIRMED_FROM_OFFICIAL_APP`, not runtime confirmation.

## Dataflow

```text
AES key generator (128 bits) -> keyBytes
NTP receive time -> Joda UTC ISO string -> createdUtf8
original password -> passwordUtf8

SHA-1(keyBytes || createdUtf8 || passwordUtf8) -> digestBytes
AES-128-ECB/PKCS#5-compatible padding(keyBytes, digestBytes)
  -> Base64 -> Password@Digest

AES-128-ECB/PKCS#5-compatible padding(keyBytes, passwordUtf8)
  -> Base64 -> Password element text

RSA/ECB/PKCS1Padding(AT public encryption key, keyBytes)
  -> Base64 -> Nonce element text
```

Java PKCS#5 padding for AES is byte-compatible with PKCS#7. The digest is not the standard WS-Security `SHA1(nonce + created + password)` representation because the XML Nonce is an RSA-encrypted AES key and both password and digest are separately AES-encrypted.

## Exact fields

| Detail | Value |
|---|---|
| Hash | SHA-1 |
| Input order | raw 16-byte AES key, Created UTF-8, password UTF-8 |
| Digest XML attribute | `Digest="base64(AES ciphertext)"` |
| Password element text | `base64(AES(password UTF-8))` |
| Nonce raw material | fresh 128-bit AES key |
| Nonce XML | `base64(RSAES-PKCS1-v1_5(aesKey))` |
| Created source | NTP receive timestamp, UTC |
| Created representation | Joda ISO-8601 UTC with millisecond precision and trailing `Z` |

## Synthetic vector

For AES bytes `00..0f`, Created `2026-08-29T12:34:56.789Z`, and password `synthetic-password`, the pre-encryption SHA-1 hex is `16f6c5f922bdc646515132f831ddb75a4589fe0b`. No real credential is used.
