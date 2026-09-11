# Capacidade de liquidações/demonstrações

## Resultado

`assessment/liquidation read available = UNKNOWN`.

Não foi encontrado WSDL/XSD público de consulta de liquidações IRS, notas ou demonstrações. O Portal oferece consulta/download ao titular, mas endpoint, contrato, autorização de automatização e lifecycle documental não foram estabelecidos.

## Valor e minimização

Valor `VERY_HIGH`: permite validar a estimativa ao cêntimo e acompanhar reembolso/pagamento. Campos mínimos: ano, tipo/estado, data, rendimento coletável, coleta, deduções, retenções/pagamentos e saldo. PDF bruto deve ser opt-in e apagado após extração confirmada; NIF, morada, IBAN, número de liquidação e referências não são necessários para cálculo.

## Gate

Exigir fluxo Portal read-only legitimamente observado, consentimento explícito, parsing sanitizado, threat model documental e runtime probe único. Até lá, a importação manual/anónima existente é a alternativa segura.
