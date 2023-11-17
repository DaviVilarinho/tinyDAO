pragma solidity ^0.8.13;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import "IProposal.sol"
import "YetAnotherToken.sol"

contract YetAnotherLossyProposal is IProposal {
  bool isFinished;
  bool isProfitable;
  ERC20 token;

  constructor() {
    isFinished = false;
    isProfitable = false;
    token = new YetAnotherToken();
  }


  function executeProposal() public {
    uint contractAllowance = token.allowance(msg.sender, address(this));
    require(contractAllowance > 0, "O contrato deve ter tokens transferíveis...");
    token.transferFrom(msg.sender, address(this), contractAllowance);
    isFinished = true;
  }
  function wasProfitable() public view { return wasProfitable; }
  function isFinished() public view { return isFinished; }
}
