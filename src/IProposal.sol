pragma solidity ^0.8.13;

import "src/IDividendManager.sol";

interface IProposal {
  function executeProposal() external;
  function distributeProfits(address proposer, IDividendManager manager) external;
}
