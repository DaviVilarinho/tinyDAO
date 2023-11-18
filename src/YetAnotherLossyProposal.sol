pragma solidity ^0.8.13;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import "src/IProposal.sol";
import "src/IDividendManager.sol";
import "src/YetAnotherToken.sol";

contract YetAnotherLossyProposal is IProposal {
  bool hasFinished;
  ERC20 token;
  int profits;

  constructor(ERC20 proposalToken) {
    hasFinished = false;
    token = proposalToken;
  }

  function generateRandomAddress() private returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number));
    return address(uint160(uint256(hash)));
  }

  function executeProposal() external {
    uint contractAllowance = token.allowance(msg.sender, address(this));
    require(contractAllowance > 0, "O contrato deve ter tokens transferiveis...");
    token.transferFrom(msg.sender, address(this), contractAllowance);
    token.transfer(generateRandomAddress(), contractAllowance);
    profits = int(token.balanceOf(address(this))) - int(contractAllowance);
    hasFinished = true;
  }
  function isFinished() public view returns(bool) { return hasFinished; }
  function getProfits() public returns (int) { return profits; }

  function distributeProfits(address proposer, IDividendManager manager) external {
    require (isFinished(), "Nao foi executado ainda!");
    manager.distributeProfits(proposer, token, getProfits());
  }
}
