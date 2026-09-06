# Catálogo de fluxos web Portal read-only

## Runtime-confirmed: documentos adquiridos

```text
open consultarDocumentosAdquirente.action
  -> acesso.gov.pt login/forward
  -> authenticated Portal session
  -> json/obterDocumentosAdquirente.action (bounded dates)
  -> split range only when response is truncated
  -> normalize minimum fields
  -> logout + destroy mode-0600 cookie file
```

| Elemento | Observação |
|---|---|
| auth/session | credencial do titular, redirects e cookie Portal temporário |
| request | intervalo temporal; parâmetros internos ficam server-side |
| response | JSON com documentos adquiridos; estrutura transformada antes da API móvel |
| stable identifiers | actions conhecidas; sem garantia pública de estabilidade |
| CSRF | login/forward/session context; não assumir que GET/POST isolado funciona |
| data | invoices, datas, valores, setor/status conforme disponibilidade upstream |
| fragility | `PORTAL_WEB_FRAGILE`; HTML/JSON privado pode mudar sem versionamento |

## Outras páginas pessoais

Atividade, Modelo 3, divergências, liquidações, pagamentos, dívida e obrigações são funcionalidades Portal observáveis, mas as respetivas routes/requests/responses não foram incorporadas porque não existe contrato oficial nem captura legitimamente disponibilizada nesta discovery. Estado: `DOCUMENTED_ONLY` ou `UNKNOWN`, não `SCHEMA_CONFIRMED`.

## API/web/mobile comparison

| Fonte | Vantagem | Limitação | Escolha atual |
|---|---|---|---|
| fatshare SOAP | schema oficial e paginação | entitlement/população prod não confirmado | investigação autorizativa |
| FactIntWS mobile | agregados e operações úteis | identidade/contexto privado; população divergente | não usar em produção |
| Portal web | população real do titular | frágil, sessão/cookies | produção apenas para received invoices |
| `api.taxy.pt` | contrato estável e sanitizado para Flutter | só pode expor semântica upstream confirmada | único caminho móvel de produção |
