# FactIntWS session and HTTP context audit

This audit is offline. It does not contain request/response payloads,
credentials, identifiers or certificate details.

## Cookie lifecycle

The official integration constructs a new `Api` inside
`WsCallerAsyncTask.executeOneRequest()` for every operation. The `Api`
constructor executes:

```text
CookieHandler.setDefault(new CookieManager())
```

Because this happens before every operation, the global cookie handler is
replaced with an empty manager between sequential requests. No explicit
`Cookie`, `Set-Cookie`, `JSESSIONID`, cookie-jar injection or session-id field
was found in the FactIntWS request path.

Conclusions:

- the official code is cookie-capable at the platform level;
- no captured response proves that FactIntWS sets a cookie;
- the official operation sequence does not intentionally preserve a cookie
  from one operation to the next;
- Taxy's lack of a cross-operation cookie jar is therefore not a demonstrated
  mismatch.

`COOKIE_STATE_MISMATCH` is **LOW** unless future sanitized response-header
evidence shows a material cookie and demonstrates that the decompiled reset
does not occur in the relevant runtime path.

## Connection lifecycle

Every official operation creates a new `Api`, `PHTBaseSOAP` and HTTPS transport.
The transport creates an `HttpsURLConnection` for that operation. The custom
code does not use ksoap2's `KeepAliveHttpsTransportSE` class. Consequently no
application-managed persistent TLS connection is evidenced.

Taxy also creates a request/connection per operation. Connection persistence is
platform-controlled in both implementations and is not a demonstrated
population selector.

## HTTP comparison

| Header/property | Official app | Taxy reference/Android | Assessment |
|---|---|---|---|
| Method | `POST` | `POST` | match |
| `Content-Type` | `text/xml;charset=utf-8` | same | match |
| `SOAPAction` | unquoted `namespace/Operation` | same | match |
| `Accept-Encoding` | `gzip` | same | match |
| `User-Agent` | `ksoap2-android/2.6.0+` | same | match |
| `Content-Length` | fixed from UTF-8 bytes | fixed from UTF-8 bytes | match |
| `Host` | platform generated | platform generated | likely irrelevant |
| `Accept` | no custom value found | no custom value | unknown/platform default |
| `Connection` | no custom value found in the used transport | no custom value | unknown/platform default |
| `Cookie` | no explicit value | none | no demonstrated requirement |
| `Cache-Control`, `Pragma`, `Expect` | no custom values found | none | likely irrelevant |
| Timeout | 120 seconds | tooling 20 seconds; Android 15/30 seconds | relevant to timeout behavior, not a completed HTTP 200 population |

No custom `X-` header, Android package, app build, device identifier or client
version outside `CanalOrigem` was found in this path.

## Authentication/application identity context

The body and WS-Security authentication are not the only identities at the
transport boundary. The official mobile app and Taxy's controlled connector do
not use the same client-certificate identity. Taxy's identity is legitimately
available and accepted by the 8443 endpoint, but acceptance does not prove that
the service applies identical population/role policy to both client
applications.

No official-app private material was used. The possibility that client
application identity affects population is recorded as
`UNKNOWN_SERVER_POPULATION_RULE` / `CLIENT_APPLICATION_IDENTITY_CONTEXT_MISMATCH`.
It is the strongest remaining context difference, but server behavior remains
an inference until documented or tested by an authorized, non-secret method.

## Selected-taxpayer server state

The selected taxpayer is stored locally in the official app and serialized on
every request. No activation operation, server-side selected-taxpayer token or
response value reused as a later selector was found. Evidence for remote
selected-taxpayer state is therefore `NO`; undocumented server state remains
`UNKNOWN` in the abstract.
