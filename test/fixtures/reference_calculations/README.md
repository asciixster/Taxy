# Reference calculations

Estes casos não são liquidações da AT. São referências manuais auditadas,
marcadas `MANUALLY_AUDITED_REFERENCE`, calculadas em cêntimos a partir dos
artigos 25.º, 59.º, 68.º, 68.º-A, 69.º, 70.º e 78.º do CIRS e das deduções
específicas indicadas em cada caso.

Cada resultado guarda valores fixos para separada e conjunta. O teste não cria
os valores esperados a partir do `TaxEngine`. Alterar uma regra ou fórmula exige
recalcular e documentar manualmente o caso; nunca atualizar números apenas para
fazer o teste passar.

O cabeçalho de cada ficheiro fixa ano, região, estado civil, versão e fontes;
cada caso contém rendimentos, retenções, Segurança Social, dependentes,
deduções, os dois resultados, modo mais favorável e notas de cálculo.

As referências cobrem casal standard e um sujeito passivo individual com
coleta positiva, sempre Categoria A, residência anual no Continente e sem
situações especiais. O caso individual 2025 documenta cada parcela do escalão,
o arredondamento e as deduções à coleta; valida consistência matemática e
regressão interna, não valida contra uma liquidação oficial da AT.
