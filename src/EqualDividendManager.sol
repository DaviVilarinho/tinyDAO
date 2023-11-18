pragma solidity ^0.8.13;

import "src/IDividendManager.sol";
import "src/DaoGovernanceToken.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";

/**
 * EqualDividendManager

 baseado na interface IDividendManager simplesmente implementa uma divisao porcentual.

 Passada como parametro na construcao, vai recompensar com base no percentual (default do TinyDAO 50)
 entao X% dos ganhos no token vai pro proposer e 100-X pro tinyDAO.

 Observe que o proprio lucro eh mintado como daotokens (ou burnado)
 */
contract EqualDividendManager is IDividendManager {
  address dao;
  DaoGovernanceToken daoGovernanceToken;
  uint proposerShare;
  constructor (address daoAddress, DaoGovernanceToken daoToken, uint proposerShareContract) {
    require(proposerShareContract <= 100);
    dao = daoAddress;
    daoGovernanceToken = daoToken;
    proposerShare = proposerShareContract;
  }

  function distributeProfits(address proposer, ERC20 token, int amount) external {
    if (amount <= 0) {
      daoGovernanceToken.punish(proposer, uint(-amount)); // se for prejuizo
      return;
    }
    uint uintamount = uint(amount);

    uint tokenAllowance = token.allowance(msg.sender, address(this));
    require(tokenAllowance > 0, "O contrato precisa repassar os lucros");
    token.transferFrom(msg.sender, address(this), tokenAllowance);  // pegar o dinheiro que deixam repassar
    daoGovernanceToken.reward(proposer, uintamount); // recompensar proposer em DaoTokens

    token.transfer(proposer, uintamount * getProposerShare() / 100); // recompensar proposer no token da transacao
    token.transfer(dao, uintamount * (100-getProposerShare()) / 100); // recompensar DAO no token da transacao
  }

  function getDaoAddress() public view returns (address) {
    return dao;
  }
  function getProposerShare() public view returns (uint) {
    return proposerShare;
  }
}
