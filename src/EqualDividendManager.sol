pragma solidity ^0.8.13;

import "IDividendManager.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";

contract EqualDividendManager is IDividendManager {
  address dao;
  ERC20 daoGovernanceToken;
  constructor (address daoAddress, ERC20 daoToken) {
    dao = daoAddress;
    daoGovernanceToken = daoToken;
  }

  function distributeProfits(address proposer, ERC20 token, int amount) public {
    if (amount <= 0) {
      daoGovernanceToken.punish(proposer, uint(-amount));
      return;
    }

    uint tokenAllowance = token.allowance(msg.sender, address(this));
    require(tokenAllowance > 0, "O contrato precisa repassar os lucros");
    token.transferFrom(msg.sender, address(this), contractAllowance);
    daoGovernanceToken.reward(proposer, uint(-amount));

    token.transfer(proposer, amount * getProposerShare() / 100);
    token.transfer(dao, amount * (100-getProposerShare()) / 100);
  }

  function getDaoAddress() public view {
    return dao;
  }
  function getProposerShare() public view {
    return 50;
  }
}
