pragma solidity ^0.8.13;

import "src/IDividendManager.sol";
import "src/DaoGovernanceToken.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";

contract EqualDividendManager is IDividendManager {
  address dao;
  DaoGovernanceToken daoGovernanceToken;
  uint proposerShare;
  constructor (address daoAddress, DaoGovernanceToken daoToken, uint proposerShareContract) {
    dao = daoAddress;
    daoGovernanceToken = daoToken;
    proposerShare = proposerShareContract;
  }

  function distributeProfits(address proposer, ERC20 token, int amount) external {
    if (amount <= 0) {
      daoGovernanceToken.punish(proposer, uint(-amount));
      return;
    }
    uint uintamount = uint(amount);

    uint tokenAllowance = token.allowance(msg.sender, address(this));
    require(tokenAllowance > 0, "O contrato precisa repassar os lucros");
    token.transferFrom(msg.sender, address(this), tokenAllowance);
    daoGovernanceToken.reward(proposer, uintamount);

    token.transfer(proposer, uintamount * getProposerShare() / 100);
    token.transfer(dao, uintamount * (100-getProposerShare()) / 100);
  }

  function getDaoAddress() public view returns (address) {
    return dao;
  }
  function getProposerShare() public view returns (uint) {
    return proposerShare;
  }
}
