# Mapa sanitizado de identidades e capacidades AT

Nenhuma chave privada, password ou PFX é copiada ou referenciada por caminho. Fingerprints identificam apenas material já legitimamente provisionado e sob controlo Taxy.

| Identidade/material | Purpose/environment | Fingerprint SHA-256 | Chain/key metadata | Endpoints com sucesso conhecido | Scope conhecido | Proveniência |
|---|---|---|---|---|---|---|
| Taxy backend client identity | mTLS backend, 2026–2028 | leaf `d9b103a05e5ac296b9563fa2f16006fb9e15bae33fb2d8a6d16a5324da43fb09`; SPKI `ddf1aa8e23a2187972a78b8dbaa856751330706a405eabcff06584a2d25eb306` | RSA; full chain 3; private key matches; clientAuth and digitalSignature | FactIntWS `:8443`: TLS 1.3, HTTP 200, SOAP | transporte/operações read aceites; população equivalente não autorizada/provada | provisionada legitimamente para Taxy/backend |
| Taxy local controlled identity | connector experimental | leaf `8c274b8bbebdfd5f86bd55e132897a87a44357b6b892e0697c362e0ecab88807` | RSA client identity; disponibilidade atual não revalidada nesta discovery | evidência histórica FactIntWS controlada | somente evidência histórica; não promover | material Taxy controlado, documentado no repo |
| AT public request-encryption key | cifrar campos WS-Security, público | certificate `43b40f7e82bf35fecce2a36778b7dd6eb4ff7bd41e88474108cb1731d3326383`; SPKI `b19983ae125123d3b82afb0845018c2fe4fc8f9556686142b1e371a031a54968` | RSA 4096; não contém segredo | FactIntWS/fatshare crypto | cifragem de pedido; não concede autorização | certificado público AT |
| Portal credentials supplied by user | sessão pessoal Portal | não existe fingerprint | password nunca persistida na app; backend protege lifecycle | Portal e-Fatura adquirido | população do próprio contribuinte autenticado | consentimento e ação explícita do titular |

## Exclusões deliberadas

Os certificados públicos da app oficial podem ser comparados como metadados, mas a respetiva identidade privada não é uma identidade Taxy e nunca pode ser usada. A igualdade do TLS handshake não prova entitlement de aplicação. A matriz de autorização em `AT_AUTHORIZATION_MATRIX.md` é por operação e não herda autorização entre serviços.
