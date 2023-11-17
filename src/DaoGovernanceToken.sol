pragma solidity >= 0.6;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";

contract DaoGovernanceToken is ERC20 {
  address owner;
  constructor() ERC20("DaoGovernanceToken", "DGT") {
    _mint(msg.sender, 1000);
  }

  function reward(address who, uint tokens) public {
      _mint(who, tokens);
  }

  function punish(address who, uint tokens) public {
    uint punishedBalance = balanceOf(who);
    if (punishedBalance < tokens) {
      _burn(who, tokens);
    } else {
      _burn(who, punishedBalance);
    }
  }
}
