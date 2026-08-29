# FactIntWS SecurityContext

The official app constructs a PKCS#12-backed key manager for mTLS. On newer Android it uses the platform trust managers; on older Android it initializes TrustKit from network security configuration and supplies that hostname-specific trust manager. A separate PEM CA loader/custom trust manager exists as a fallback path that augments built-in root validation.

This demonstrates:

- client-certificate authentication (`mTLS`);
- custom trust augmentation on some platform paths;
- built-in-root validation first, then explicit CA validation in the custom manager;
- a preferred cipher-suite socket-factory wrapper.

No independent public-key comparison or hostname pin value was found in the reconstructed call path. Therefore `CERTIFICATE_PINNING = UNKNOWN`; `CUSTOM_TRUST_STORE = YES`. TrustKit's presence alone is not proof of pinning.

The APK asset inventory includes production/quality client certificates and private-key containers, a master CA bundle, BKS public-encryption-key material, and legacy PFX assets. These were inventoried by role only. None was read, exported, used, or committed. Taxy must use only its separately legitimate PFX and trusted public AT encryption key material.
