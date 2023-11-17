pragma solidity >=0.6;

import {ERC20} from "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import {Test} from "forge-std/Test.sol";
import {TinyDao} from "TinyDao.sol";

contract TinyDaoTest is Test {
  address daoOwner = address(0x1);
  address daoShareholder1 = address(0x11);
  address daoShareholder2 = address(0x12);
  uint MAX_CONCURRENT_PROPOSALS = 2;
  uint BASE_SHAREHOLDERS_AMOUNT = 300;
  TinyDao tinyDao;

  function setUp() {
    vm.startPrank(daoOwner);
    tinyDao = new TinyDao(MAX_CONCURRENT_PROPOSALS);
    tinyDao.getDaoGovernanceToken().transfer(daoShareholder1, BASE_SHAREHOLDERS_AMOUNT);
    tinyDao.getDaoGovernanceToken().transfer(daoShareholder2, BASE_SHAREHOLDERS_AMOUNT);
    vm.stopPrank();
  }

  function
}
