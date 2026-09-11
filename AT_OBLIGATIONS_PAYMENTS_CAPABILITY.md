# Obrigações, pagamentos e dívida

## Resultado

`payments/debt read = UNKNOWN`; `obligations read = UNKNOWN`.

O WSDL de Obrigações Acessórias comunica DMR e vários modelos: é um serviço de entrega, não a lista pessoal de obrigações pendentes. Não foram encontrados contratos públicos de consulta de documentos de cobrança, pagamentos, dívida, prestações ou declarações em falta.

| Capability | Valor | Risco | Minimal fields/cache | Estado |
|---|---|---|---|---|
| obrigação pendente | VERY_HIGH | alertas falsos/legal wording | tipo, período, estado, data oficial; SHORT_CACHE | UNKNOWN |
| documento de cobrança | HIGH | referência de pagamento sensível | estado/valor; NO_STORE; omitir referência | UNKNOWN |
| pagamento efetuado | HIGH | histórico financeiro | data/status/valor; SESSION_ONLY | UNKNOWN |
| dívida/prestações | HIGH | sensível e potencialmente alarmista | aggregate/status; SESSION_ONLY | UNKNOWN |

Qualquer alert deve reproduzir estado oficial e timestamp, sem inventar prazo/coima. Não executar operações do WSDL de comunicação nesta investigação.
