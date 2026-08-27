# IRS Jovem reference calculations

Estes casos são `MANUALLY_AUDITED_REFERENCE`; não são liquidações oficiais da
AT. Os valores esperados estão fixos em cêntimos e foram revistos passo a passo
com as regras 2025.4.0, sem obter o esperado através do motor durante o teste.

Método auditado:

1. apurar dedução específica e mínimo de existência;
2. apurar rendimento coletável normal;
3. limitar a isenção à percentagem do rendimento A e a 55 IAS;
4. subtrair a isenção ao coletável, sem permitir resultado negativo;
5. adicionar a parcela isenta, sem deduções, para determinar a taxa (artigo
   22.º, n.º 4, do CIRS);
6. calcular a coleta sobre o rendimento para taxa e retirar a fração
   proporcional correspondente ao rendimento isento;
7. aplicar deduções à coleta, solidariedade e retenções sem as alterar.

Em tributação conjunta, o rendimento para taxa usa o quociente conjugal 2; a
coleta resultante é multiplicada por dois antes da imputação proporcional da
parcela isenta. A separada liquida cada titular individualmente.

Os ficheiros desta pasta nunca podem usar `source: OFFICIAL_AT_ASSESSMENT`.
Casos reais anonimizados pertencem a `../../official_assessments/`.
