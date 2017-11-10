pragma solidity ^0.4.15;
/* Essa primeira linha tem que ser incluída em todo contrato, informando a versão do solidity
   que o compilador deve usar. */

contract VotoSecreto {
  // Auto explicativo, aqui declaramos o nome do contrato.

  mapping (bytes32 => uint8) public votosRecebidos;
  /* Mapping é uma cadeia (array) associativa. No caso acima é uma cadeia que contém em cada os
     candidatos e o número de votos. Apesar de arrays existirem no solidity, o mapping é mais
     recomendado pois consome menos processamento quando é necessário fazer uma busca,
     principalmente em cadeias grandes. Menos processamento = menos gas = um contrato com
     execução mais barata. (http://solidity.readthedocs.io/en/develop/types.html) */

  mapping (address => bool) public eleitores;
  /* Lista de eleitores, percebam que não vamos registrar os votos deles. O objetivo aqui é
     registrar os eleitores e tornar o processo auditável. Basicamente o número total de
     eleitores deve ser igual ao número total de votos. */

  uint256 public totalDeVotos;
  uint256 public totalDeEleitores;
  // total de votos registrados

  uint8 public status; // 0 = não iniciada, 1 = aberta, 2 = finalizada
  /* Estado da eleição, definido na criação do contrato como "Não iniciada", podendo
     ser alterado somente pelo porprietário do contrato */

  bytes32[] public listaDeCandidatos;
  /* Lista de candidatos. Não podemos usar o mapping nesse caso porque essa array será
     passada como parâmetro na criação do contrato, e mappings (por enquanto) não
     podem ser passados como parâmetros */

  address public proprietario; // variável para registrar o dono (criador) do contrato


  function VotoSecreto(bytes32[] nomesCandidatos) public {
    listaDeCandidatos = nomesCandidatos;
    proprietario = msg.sender;
    status = 0;
  }
  /* A função acima é a função construtora (constructor) do contrato. Ela é opcional,
     mas se for usada deve ter o mesmo nome do contrato. A diferença dela para as demais
     é que a função construtora é chamada somente uma vez, na criação do contrato. Aqui
     no nosso exemplo ela recebe a lista de candidatos para a eleição. */

  function() payable public { }
  /* essa função sem nome é chamada de "Fallback function", e é executada toda vez que
     alguém manda algum valor em ETH para o contrato. No nosso caso ela está em branco,
     então o ETH é recebido porém nada mais vai ser executado. Ela é importante porque
     sem ela, o contrato não pode receber pagamentos, e nós não queremos uma eleição
     interrompida porque faltou gás para o contrato, certo? */

  function totalDeVotosPara(bytes32 candidato) public returns (uint8) {
    if (candidatoValido(candidato) == false) revert(); // valida se o endereço recebido é de um candidato
    return votosRecebidos[candidato];
  }
  // Função que retorna o total de votos de um candidato.

  function votarPara(bytes32 candidato) public {
    if (candidatoValido(candidato) == false || eleitorValido(msg.sender) != false || status != 1) revert(); // valida se o endereço recebido é de um candidato, valida se o eleitor pode votar e se já reistrou o voto
    eleitores[msg.sender] = true; // registra o candidato na lista de eleitores, para mudar o voto para não secreto basta substituir o bool acima pelo candidato.
    votosRecebidos[candidato] += 1; // soma um voto para o candidato
    totalDeVotos += 1;
  }
  /* Função de voto. Registra o voto para um candidato, e inclui o eleitor na lista
     de votantes, impossibilitando outras tentativas de voto (cada eleitor vota somente uma vez). */


  function candidatoValido(bytes32 candidato) public returns (bool) {
    for(uint i = 0; i < listaDeCandidatos.length; i++) {
      if (listaDeCandidatos[i] == candidato) {
        return true;
      }
    }
    return false;
  }
  // Função que verifica se o candidato é válido (se ele está na lista de candidatos)

  function eleitorValido(address eleitor) private returns (bool) {
    return eleitores[eleitor];
  }
  /* Função que verifica se o eleitor é válido (se ele é autorizado a votar e se ele
     já votou). Retorna null se ele não foi autorizado. */

  function adicionaEleitor(address eleitorNovo) somenteProprietario public {
    if (status == 2 || status == 1) revert();
    eleitores[eleitorNovo] = false;
    totalDeEleitores += 1;
  }
  /* Função para adição de eleitores. Todos os eleitores devem ser informados ANTES DO
     INÍCIO da eleição. */

  function iniciaEleicao() somenteProprietario public {
    if (status == 2) revert();
    status = 1;
  }
  // Função que abre a eleição para votos

  function finalizaEleicao() somenteProprietario public {
    if (status == 2) revert();
    status = 2;
    proprietario.transfer(this.balance);
  }
  /* Função que fecha a eleição para votos. Após a finalização da eleição ela não pode
     mais ser aberta, e as funções de consulta não tem custo de gás, então ela também
     envia o que houver the ETH na carteira do contrato para o criador do mesmo. Pronto,
     a eleição fica gravada para sempre no blockchain, completamente auditável e sem
     mais nenhum custo :)  */

  modifier somenteProprietario {
      require(msg.sender == proprietario);
      _;
  }
  /* A função modifier serve para validar alguma condição antes de executar o código.
     Ver funcões de início e fim da eleição para entender melhor. Aqui o código
     da função que chamou esse modifier seria executada no "_", então se a função
     for chamada por outra pessoa não é executada. */

}
