pragma solidity ^0.8.13;

import "DividendManager.sol"

interface IProposal {
  function executeProposal() public;
  function wasProfitable() public view;
  function isFinished() public view;
  function distributeProfits(address dao, address proposer, DividendManager manager);
}
