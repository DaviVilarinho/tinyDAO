pragma solidity ^0.8.13;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";

interface IDividendManager {
  function distributeProfits(address proposer, ERC20 token, int amount) public;
  function getDaoAddress() public view;
  function getProposerShare() public view;
}
