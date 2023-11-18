pragma solidity >= 0.6;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";

// token dummy para usar em testes
contract YetAnotherToken is ERC20 {
    constructor() ERC20("YetAnotherToken", "YAT") {
      _mint(msg.sender, 100000);
    }
}
