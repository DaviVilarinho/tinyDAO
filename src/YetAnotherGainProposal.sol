pragma solidity ^0.8.13;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import "src/IProposal.sol";
import "src/IDividendManager.sol";
import "src/YetAnotherToken.sol";

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

  function generateRandomAddress() private returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number));
    return address(uint160(uint256(hash)));
  }

  function executeProposal() external {
    uint contractAllowance = token.allowance(charitableOne, address(this));
    token.transferFrom(charitableOne, address(this), contractAllowance);
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
