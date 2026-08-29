# FactIntWS SecurityContext

The official app constructs a PKCS#12-backed key manager for mTLS. On newer Android it uses the platform trust managers; on older Android it initializes TrustKit from network security configuration and supplies that hostname-specific trust manager. A separate PEM CA loader/custom trust manager exists as a fallback path that augments built-in root validation.

This demonstrates:

- client-certificate authentication (`mTLS`);
- custom trust augmentation on some platform paths;
- built-in-root validation first, then explicit CA validation in the custom manager;
- a preferred cipher-suite socket-factory wrapper.

The APK network-security configuration contains an enforced TrustKit SHA-256
pin-set scoped to the service hostname (without subdomains). Therefore
`CERTIFICATE_PINNING = YES` and `CUSTOM_TRUST_STORE = YES`. Pin values are not
copied into Taxy: this task records behavior and does not import app trust data.

The Taxy live harness currently uses normal platform CA validation with
`rejectUnauthorized = true`; application-level pinning is `NOT_IMPLEMENTED`.
That is a client-side hardening difference, not evidence of server protocol
incompatibility, and certificate validation is not disabled.

The local `TesteWebservices.pfx` preflight is `READY`: the PKCS#12 opens, its
private key is present, it contains three certificates, its chain validates, and
the leaf EKU permits TLS Web Client Authentication. Sanitized transport
diagnostics capture handshake stage, TLS version, cipher, authorization state and
OpenSSL category without certificate or secret material. This is offline
readiness, not runtime acceptance by FactIntWS.

The APK asset inventory includes production/quality client certificates and private-key containers, a master CA bundle, BKS public-encryption-key material, and legacy PFX assets. These were inventoried by role only. None was read, exported, used, or committed. Taxy must use only its separately legitimate PFX and trusted public AT encryption key material.

## TLS 1.2-only experiment

One controlled request set both `minVersion` and `maxVersion` to `TLSv1.2`, with
no custom cipher list and no other protocol change. The endpoint returned TLS
alert 40 (`handshake failure`) before `secureConnect`. No protocol, cipher, ALPN,
HTTP or SOAP metadata was available. TLS 1.2 is therefore not runtime-confirmed.

With the original negotiation restored and only the endpoint changed to port
8443, the same legitimate client identity reached `secureConnect`, was authorized
and negotiated TLS 1.3 with `TLS_AES_128_GCM_SHA256`. The request then received
HTTP 200 and a functional SOAP response. This confirms the 8443 TLS profile for
the controlled read-only operation; application pinning remains unimplemented.
