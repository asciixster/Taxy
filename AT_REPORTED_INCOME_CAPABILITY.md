# Capacidade de rendimentos comunicados

## Resultado

`reported income read available = UNKNOWN`.

Foram encontrados schemas oficiais de entrega (Modelo 10, DMR, Modelo 3 e obrigações acessórias) e funcionalidades Portal/declaração pré-preenchida, mas nenhum WSDL/REST público de consulta dos rendimentos pessoais comunicados por terceiros. Um schema de submissão não é uma API de leitura.

| Interesse | Fonte oficial encontrada | Read endpoint | Estado |
|---|---|---|---|
| Categoria A e retenções | Modelo 10/DMR e pré-preenchimento Portal | não publicado | NOT_AVAILABLE |
| pensões | declaração/preenchimento oficial | não publicado | NOT_AVAILABLE |
| recibos verdes/Categoria B | ATGo receitas e documentos; fatshare emitente | só fatshare genérico, auth desconhecida | AUTH_UNKNOWN |
| rendimentos estrangeiros | Modelo 3/Anexo J schema de entrega | não publicado | NOT_AVAILABLE |
| outros valores por terceiros | modelos acessórios | comunicação write | NOT_AVAILABLE |

## Consequência de produto

Manter pergunta/entrada documental; não declarar prefill oficial. Uma futura fonte deve devolver apenas categoria, período, montante e retenção necessários, com consentimento e confirmação para conflitos.
