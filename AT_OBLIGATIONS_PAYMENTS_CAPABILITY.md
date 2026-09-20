# Obrigações, pagamentos e dívida

## Resultado

`payments/debt read = YES`; `obligations read = PARTIAL` through authenticated
Portal read flows.

O WSDL de Obrigações Acessórias comunica DMR e vários modelos: é um serviço de entrega, não a lista pessoal de obrigações pendentes. Não foram encontrados contratos públicos de consulta de documentos de cobrança, pagamentos, dívida, prestações ou declarações em falta.

| Capability | Valor | Risco | Minimal fields/cache | Estado |
|---|---|---|---|---|
| obrigação/agenda pendente | VERY_HIGH | alertas falsos/legal wording | tipo, período, estado, data oficial; SHORT_CACHE | RUNTIME_READ_CONFIRMED (empty account) |
| documento de cobrança | HIGH | referência de pagamento sensível | estado/valor; NO_STORE; omit reference | SCHEMA_CONFIRMED |
| pagamento a decorrer | HIGH | histórico financeiro | date/status/value; SESSION_ONLY | RUNTIME_READ_CONFIRMED (empty account) |
| dívida/coima/prestações | HIGH | sensitive and potentially alarming | aggregate/status; SESSION_ONLY | RUNTIME_READ_CONFIRMED (empty account) |

Qualquer alert deve reproduzir estado oficial e timestamp, sem inventar prazo/coima. Não executar operações do WSDL de comunicação nesta investigação.
