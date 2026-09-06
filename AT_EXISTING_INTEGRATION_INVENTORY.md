# Inventário das integrações AT existentes

Data de corte: 2026-09-06. Este inventário separa código executável, evidência histórica e capacidade apenas observada em produtos oficiais. Não altera produção.

| Componente | Endpoint/protocolo | Autenticação | Read/write | Estado e evidência | Ficheiros relevantes |
|---|---|---|---|---|---|
| e-Fatura público da Taxy | `Flutter -> api.taxy.pt -> Portal e-Fatura` / HTTPS JSON | sessão Taxy curta; credencial Portal tratada no backend | read-only | `RUNTIME_READ_CONFIRMED`: overview normalizado, pendentes e faturas recebidas em Android real | `EFATURA_BACKEND_BRIDGE.md`, `lib/modules/efatura/` |
| Reader Portal adquirido | `consultarDocumentosAdquirente.action` + `json/obterDocumentosAdquirente.action` | login Portal, cookie temporário | read-only | `RUNTIME_READ_CONFIRMED`; divide intervalos truncados e destrói cookie | `EFATURA_BACKEND_BRIDGE.md` |
| FactIntWS | `:8443/mobile/a4/factintws/ws`, SOAP 1.1 | mTLS Taxy + WS-Security AT | mixed | três reads com dispatch runtime; população vazia sob contexto Taxy; quatro writes bloqueados | `tools/at_connector/src/factintws.mjs`, `FACTINTWS_EVIDENCE_MATRIX.md` |
| fatshare e-Fatura | portas 725/425, SOAP 1.1 | mTLS + WS-Security | read-only | WSDL de consulta agora público; teste histórico chegou a HTTP 200/estado 486 vazio, mas autorização de população de produção não está confirmada | `tools/at_connector/src/consultation.mjs`, `AT_PROTOCOL_EVIDENCE.md` |
| fatcore e-Fatura | portas 723/423, SOAP 1.1 | mTLS + WS-Security | write | contrato oficial de registo/alteração/eliminação; guard de produção e nenhuma execução nesta discovery | `tools/at_connector/src/submission.mjs`, `AT_CONNECTOR.md` |
| Parser/normalização e-Fatura | local | n/a | read transform | modelos sanitizados; `unavailable != zero`; sem IDs/NIFs no contrato móvel | `lib/modules/efatura/`, `EFATURA_AGGREGATES_AVAILABILITY.md` |
| Importação de liquidações | ficheiros locais anonimizados | utilizador | local read | validação fiscal offline; não consulta AT | `AT_VALIDATION.md`, `AT_FIELD_MAPPING.md` |
| Modelo 3/IRC/IVA/IES | schemas e WSDL públicos | variável | maioritariamente write | formatos de entrega e validação, não APIs pessoais de consulta | `AT_OFFICIAL_SOURCES.md`, `AT_ENDPOINT_CATALOG.md` |

## Pesquisa transversal

Foram pesquisadas referências a AT, Portal, webservices, FactIntWS, fatshare, faturação/e-Fatura, declarações, liquidações, pagamentos, atividade, CAE/CIRS, IVA/VIES, retenções, IRS/IES/Modelos 3 e 22. Não existe no repositório outro connector executável para perfil cadastral, rendimentos comunicados, declarações, liquidações, dívida ou obrigações.

## Conclusão

O único caminho pessoal read-only de produção confirmado é o reader Portal para faturas recebidas, exposto exclusivamente por `api.taxy.pt`. FactIntWS é evidência de protocolo e autorização de transporte/operação, não uma fonte de população equivalente à app oficial. Os restantes contratos públicos encontrados servem sobretudo comunicação/entrega.
