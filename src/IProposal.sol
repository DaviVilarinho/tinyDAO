pragma solidity ^0.8.13;

import "DividendManager.sol"

interface IProposal {
  function executeProposal() public;
  function isFinished() public view;
  function getProfits() returns int;
  function distributeProfits(address proposer, DividendManager manager);
}
