pragma solidity ^0.8.13;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import "src/IProposal.sol";
import "src/IDividendManager.sol";
import "src/YetAnotherToken.sol";

/**
 * YetAnotherGainProposal
 Eh um contrato proposal que recebe uma doacao do instanciador e repassa para dao+proposer, entao sempre tem lucro
 */
contract YetAnotherGainProposal is IProposal {
  bool hasFinished;
  ERC20 token;
  int profits;
  address charitableOne;

  constructor(ERC20 proposalToken) {
    hasFinished = false;
    token = proposalToken;
    charitableOne = msg.sender;
  }

  function executeProposal() external {
    uint contractAllowance = token.allowance(charitableOne, address(this));
    token.transferFrom(charitableOne, address(this), contractAllowance); // pega dinheiro do instanciador
    profits = int(contractAllowance);
    hasFinished = true;
  }
  function isFinished() public view returns(bool) { return hasFinished; }
  function getProfits() public returns (int) { return profits; }

  function distributeProfits(address proposer, IDividendManager manager) external {
    require (isFinished(), "Nao foi executado ainda!");
    if (profits > 0) {
      token.approve(address(manager), uint(profits));
    }
    manager.distributeProfits(proposer, token, getProfits());
  }
}
