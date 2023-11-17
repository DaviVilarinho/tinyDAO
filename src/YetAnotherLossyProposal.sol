pragma solidity ^0.8.13;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import "IProposal.sol"
import "YetAnotherToken.sol"

contract YetAnotherLossyProposal is IProposal {
  bool isFinished;
  ERC20 token;
  int profits;

  constructor() {
    isFinished = false;
    token = new YetAnotherToken();
  }


  function executeProposal() public {
    uint contractAllowance = token.allowance(msg.sender, address(this));
    require(contractAllowance > 0, "O contrato deve ter tokens transferíveis...");
    token.transferFrom(msg.sender, address(this), contractAllowance);
    token.transfer(0x0, contractAllowance);
    profits = token.balanceOf(address(this)) - contractAllowance;
    isFinished = true;
  }
  function isFinished() public view { return isFinished; }
  function getProfits() returns int { return profits; }

  function distributeProfits(address proposer, DividendManager manager) {
    require (isFinished(), "Nao foi executado ainda!");
    manager.distributeProfits(proposer, token, getProfits()) public;
  }
}
