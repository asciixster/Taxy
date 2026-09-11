# Capacidade de documentos/faturas emitidos

## Resultado

`issued invoices read available = UNKNOWN` para produção Taxy. O schema oficial é confirmado e oferece a maior oportunidade técnica ainda não autorizada.

`fatshareInvoices.wsdl` e os manuais e-Fatura definem `InvoicesRequest` com escolha exclusiva entre emitente (`TaxRegistrationNumber`) e adquirente (`CustomerTaxID`), intervalo e paginação. A resposta inclui tipo/data, valores líquido/IVA/bruto e identificadores. O pedido por emitente é semanticamente read-only.

## Populações distintas

1. Documentos comunicados pelo próprio software Taxy: Taxy pode conhecer os seus próprios writes, mas isso não existe no produto atual e não é “consulta AT”.
2. Documentos existentes na AT por emitente: capability fatshare pretendida.
3. Dados do consumidor/adquirente: Portal e FactIntWS, contrato/população diferentes.
4. ATGo: emite e consulta documentos no contexto oficial, mas não fornece API pública Taxy.

## Campos mínimos propostos

Data, tipo de documento, bruto, líquido, IVA, moeda quando aplicável e estado. `InvoiceNo`, ATCUD, NIF de cliente e nomes só devem entrar se um caso de uso explícito o exigir; não devem ser devolvidos automaticamente ao Flutter.

## Bloqueio

O teste histórico fatshare confirmou dispatch/response vazio em sandbox, não autorização da identidade backend para a população real emitida. Antes de implementação: confirmar junto da AT o perfil/subutilizador exigido, testar uma única consulta read-only em ambiente autorizado e obter fixture sanitizada.
