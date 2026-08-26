# Casos do Tax Engine

Os valores esperados são expressos em cêntimos nos testes automatizados para eliminar ambiguidades de arredondamento.

| # | Cenário | Input essencial | Resultado esperado |
|---:|---|---|---|
| 1 | Zero | coletável 0 € | coleta 0 € |
| 2 | Limite escalão 1 | coletável 8.342 € | coleta 1.042,75 € |
| 3 | Após escalão 1 | coletável 8.343 € | coleta 1.042,91 € |
| 4 | Limite escalão 2 | coletável 12.587 € | coleta 1.709,22 € |
| 5 | Após escalão 2 | coletável 12.588 € | coleta 1.709,40 € |
| 6 | Limite escalão 8 | coletável 86.634 € | coleta 30.197,28 € |
| 7 | Após escalão 8 | coletável 86.635 € | coleta 30.197,63 € |
| 8 | Mínimo de existência | bruto 12.880 € | imposto devido 0 € |
| 9 | Dedução específica | bruto 30.000 €; SS 3.300 € | dedução 4.587,09 € |
| 10 | SS superior | bruto 50.000 €; SS 6.000 € | dedução 6.000 € |
| 11 | Retenção | mesma coleta com retenção | saldo aumenta exatamente pela retenção |
| 12 | Gerais acima do teto | 10.000 € | crédito máximo 250 € |
| 13 | Saúde acima do teto | 10.000 € | crédito máximo 1.000 € |
| 14 | PPR, 34 anos | 3.000 € | crédito máximo 400 € |
| 15 | PPR, 40 anos | 3.000 € | crédito máximo 350 € |
| 16 | PPR, 55 anos | 3.000 € | crédito máximo 300 € |
| 17 | Dependente adulto | um dependente | crédito 600 € antes do limite global |
| 18 | Dependente até 3 | primeiro dependente | majoração 126 € |
| 19 | Segundo até 6 | dois dependentes | majoração adicional 300 € |
| 20 | Solidariedade | coletável superior a 80.000 € | adicional de 2,5% no excedente |
| 21 | Madeira | região Madeira | resultado indisponível |
| 22 | Tributação conjunta | modo conjunto | resultado indisponível |
| 23 | Residência parcial | residente parte do ano | resultado indisponível |
| 24 | Persistência | encode/decode | todos os cêntimos preservados |
| 25 | Sem dependentes | questionário | salta idades |
| 26 | Com dependentes | questionário | pede idades |
| 27 | Solteiro | questionário | salta modo conjunto/separado |

Implementação executável em `test/tax_engine_test.dart`; arranque e carregamento de assets em `test/widget_test.dart`.
