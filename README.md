# tinyDAO

Isto é uma implementação de uma DAO feita como uma atividade para entender:
1. o funcionamento
2. a complexidade
3. a interface

De uma DAO.

Realizada apenas em solidity e foundry, testei com `forge test -vvv -via-ir` se assim for de seu interesse testar.

## DAO

Aos que não conhecem, uma DAO seria uma organização descentralizada, uma *empresa* não centralizada, ou seja, baseado apenas em votação, como podemos organizar a empresa? Votando no que ela faz, ora!

Então o funcionamento é simples, porém cheio de minúcias:
- criar, como distribuir os tokens de governança? Para o instanciador? E como receber o patrimônio inicial?
- propor algo para ser executado
- votar (proporcionalmente aos DAO Tokens)
- executar ao votar ok ou simplesmente não executar
- controlar quantidade de propostas
- organizar distribuição: neste caso usei um padrão de código similar ao *Strategy*, recebe um contrato que decide como distribuir...

