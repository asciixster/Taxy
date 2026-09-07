# Pedido técnico à AT — acesso read-only DM3IRS

**Assunto:** Pedido de informação técnica sobre integração read-only com serviços DM3IRS

Exmos. Senhores,

Estamos a desenvolver a Taxy, uma aplicação portuguesa de apoio à organização da informação fiscal e à produção de estimativas de IRS. Pretendemos avaliar uma integração oficial, consentida pelo contribuinte e estritamente de leitura com a família de serviços DM3IRS, sem submissão de declarações nem qualquer outra alteração de dados no Portal das Finanças.

O objetivo funcional seria reduzir introdução manual, permitir ao contribuinte confirmar informação oficial relevante e, quando autorizado, acompanhar o estado de uma declaração. Toda a integração seria mediada pela nossa infraestrutura, com minimização de dados, segregação por ano fiscal, consentimento explícito, auditoria e ausência de operações de escrita.

Solicitamos, por favor, esclarecimento sobre os seguintes pontos:

1. A família DM3IRS é disponibilizada a entidades ou aplicações externas à AT?
2. Existe processo formal de adesão, credenciação ou celebração de protocolo para integradores terceiros?
3. Pode um certificado cliente controlado pelo integrador ser emitido ou autorizado para mTLS?
4. Existe ambiente de qualidade/homologação acessível a integradores, com dados de teste não pessoais?
5. Que operações de consulta/read-only podem ser disponibilizadas, nomeadamente catálogos, informação do utilizador/agregado, estado de entrega, recibo/comprovativo e consulta de declaração?
6. Podem ser fornecidos os WSDL/XSD oficiais, SOAPActions, versões e política de compatibilidade/depreciação?
7. Existem scopes ou entitlements distintos por operação, ambiente, certificado ou perfil de utilizador?
8. Quais são os limites de utilização, rate limits, timeouts e regras de retry/polling?
9. Que requisitos específicos se aplicam ao tratamento, minimização, conservação, auditoria e eliminação de dados pessoais/fiscais?
10. É permitido utilizar estas consultas numa aplicação destinada ao próprio contribuinte, mediante autenticação e consentimento explícito deste?
11. Existe procedimento de homologação técnica e de segurança antes de acesso a produção? Que evidências/testes são exigidos?
12. Qual é o contacto/equipa técnica apropriado para prosseguir esta avaliação?

Para uma primeira validação, propomos solicitar apenas acesso read-only ao ambiente de qualidade, começar por uma consulta de catálogos sem dados pessoais e executar no máximo uma chamada por etapa. Não pretendemos obter autorização para submissão de declarações nesta fase.

Estamos disponíveis para apresentar arquitetura, modelo de consentimento, medidas de segurança, política de retenção e identificação da entidade responsável pelo tratamento.

Com os melhores cumprimentos,

**Taxy**

[entidade legal]

[contacto técnico]

[contacto de privacidade/DPO, se aplicável]
