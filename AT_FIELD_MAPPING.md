# AT field mapping

Este documento orienta a transcrição manual de uma demonstração de liquidação
da Autoridade Tributária para uma fixture Taxy. A apresentação e os rótulos dos
documentos podem variar por ano e tipo de documento. O operador deve confirmar
sempre o significado no documento concreto; uma semelhança textual não autoriza
uma equivalência fiscal.

`NO_DIRECT_AT_FIELD` significa que o trace Taxy é uma fase interna ou uma
decomposição sem linha autónoma garantida na demonstração. Esse valor só deve ser
preenchido quando o documento real o apresente de forma inequívoca.

| Conceito Taxy | Campo/linha típica da demonstração AT | Estado |
| --- | --- | --- |
| `grossIncomeCents` | Rendimento global / rendimento bruto da categoria | CONFIRM_ON_DOCUMENT |
| `specificDeductionCents` | Deduções específicas | CONFIRM_ON_DOCUMENT |
| `netIncomeCents` | Rendimento líquido da categoria | NO_DIRECT_AT_FIELD |
| `minimumExistenceAllowanceCents` | Mínimo de existência / redução associada | NO_DIRECT_AT_FIELD |
| `taxableIncomeCents` | Rendimento coletável | DIRECT_TYPICAL_LABEL |
| `maritalQuotient` | Quociente conjugal / número de sujeitos passivos usado como divisor | CONFIRM_ON_DOCUMENT |
| `rateDeterminingIncomeCents` | Rendimento para determinação da taxa | CONFIRM_ON_DOCUMENT |
| `rateDeterminingQuotientCents` | Rendimento para taxa depois do quociente conjugal | NO_DIRECT_AT_FIELD |
| `bracketBaseTaxCents` | Parcela/base apurada antes da taxa marginal | NO_DIRECT_AT_FIELD |
| `bracketExcessCents` | Excesso dentro do escalão marginal | NO_DIRECT_AT_FIELD |
| `marginalRatePpm` | Taxa aplicável | CONFIRM_ON_DOCUMENT |
| `taxBeforeExemptionCents` | Coleta antes da imputação proporcional da isenção | NO_DIRECT_AT_FIELD |
| `exemptIncomeCents` | Rendimento isento sujeito a englobamento para taxa | CONFIRM_ON_DOCUMENT |
| `taxAllocatedToExemptIncomeCents` | Coleta imputada ao rendimento isento | NO_DIRECT_AT_FIELD |
| `grossTaxAfterExemptionCents` | Coleta total, antes das deduções à coleta | CONFIRM_ON_DOCUMENT |
| `dependentCreditsCents` | Dedução à coleta por dependentes | CONFIRM_ON_DOCUMENT |
| `generalExpenseCreditCents` | Despesas gerais familiares | CONFIRM_ON_DOCUMENT |
| `healthCreditCents` | Saúde | CONFIRM_ON_DOCUMENT |
| `educationCreditCents` | Educação | CONFIRM_ON_DOCUMENT |
| `careHomeCreditCents` | Lares | CONFIRM_ON_DOCUMENT |
| `rentCreditCents` | Encargos com imóveis/rendas elegíveis | CONFIRM_ON_DOCUMENT |
| `invoiceVatCreditCents` | IVA por exigência de fatura | CONFIRM_ON_DOCUMENT |
| `pprCreditCents` | Benefícios fiscais/PPR | CONFIRM_ON_DOCUMENT |
| `overallDeductionsCapCents` | Limite global de deduções | NO_DIRECT_AT_FIELD |
| `totalTaxCreditsCents` | Total das deduções à coleta | CONFIRM_ON_DOCUMENT |
| `solidarityTaxCents` | Taxa adicional de solidariedade | CONFIRM_ON_DOCUMENT |
| `finalTaxDueCents` | Imposto apurado / coleta líquida, conforme o documento | CONFIRM_ON_DOCUMENT |
| `withholdingCents` | Retenções na fonte | DIRECT_TYPICAL_LABEL |
| `balanceCents` | Valor a reembolsar ou valor a pagar | CONFIRM_SIGN_AND_LABEL |

## IRS Jovem

Estes conceitos não são intercambiáveis:

- `exemptIncomeCents` é a parcela de rendimento abrangida pela isenção;
- `rateDeterminingIncomeCents` inclui a parcela isenta quando esta releva para
  determinar a taxa aplicável;
- `taxAllocatedToExemptIncomeCents` é a parte da coleta imputada ao rendimento
  isento e retirada à coleta antes das deduções;
- `rateDeterminingQuotientCents` é o rendimento usado nos escalões depois de
  aplicado o divisor conjugal, quando existe tributação conjunta.

Se a demonstração não individualizar uma destas fases, usar
`NO_DIRECT_AT_FIELD`: deixar o campo ausente é mais seguro do que inferir o
valor por diferença.

## Regras de transcrição

1. Transcrever apenas valores visíveis e semanticamente confirmados.
2. Guardar dinheiro em cêntimos inteiros e taxas em partes por milhão (`ppm`).
3. Confirmar o sinal do saldo: positivo na Taxy significa reembolso; negativo,
   imposto adicional a pagar.
4. Explicar em `sourceNotes` a linha/área usada, sem copiar identificadores.
5. Classificar dúvidas de correspondência como `INPUT_MAPPING_ERROR` ou
   `UNKNOWN`; nunca corrigir automaticamente o motor.
