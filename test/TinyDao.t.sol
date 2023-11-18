import {ERC20} from "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import {Test} from "forge-std/Test.sol";
import "src/TinyDAO.sol";
import "src/YetAnotherToken.sol";
import "src/YetAnotherLossyProposal.sol";
import "src/YetAnotherGainProposal.sol";

contract TinyDAOTest is Test {
  address daoOwner = address(0x1);
  address daoShareholder1 = address(0x11);
  address daoShareholder2 = address(0x12);
  uint MAX_CONCURRENT_PROPOSALS = 2;
  uint BASE_SHAREHOLDERS_AMOUNT = 300;
  TinyDAO tinyDAO;
  ERC20 yat;
  IProposal acceptedProposal;
  IProposal gainProposal;

  uint startingShare = 50;
  uint startingGainOffered = 100;

  function setUp() public {
    vm.startPrank(daoOwner);
    yat = new YetAnotherToken();
    acceptedProposal = new YetAnotherLossyProposal(yat);
    gainProposal = new YetAnotherGainProposal(yat);
    yat.approve(address(gainProposal), startingGainOffered);
    tinyDAO = new TinyDAO(MAX_CONCURRENT_PROPOSALS);
    tinyDAO.getDaoGovernanceToken().transfer(daoShareholder1, BASE_SHAREHOLDERS_AMOUNT);
    tinyDAO.getDaoGovernanceToken().transfer(daoShareholder2, BASE_SHAREHOLDERS_AMOUNT);
    yat.transfer(address(tinyDAO), 5000);
    vm.stopPrank();
  }

  uint idAccepted = 1;
  uint idRejected = 999;
  string description = "aceitar";

  function testCanCreateProposal() public {
    vm.expectRevert(); // n pode quem n tem token
    tinyDAO.doProposal(idAccepted,description,yat,acceptedProposal,1);

    vm.startPrank(daoOwner);
    tinyDAO.doProposal(idAccepted,description,yat,acceptedProposal,1);
    vm.stopPrank();
  }

  function testCanProposeAgainWhenVotedAndAtLimitBefore() public {
    vm.startPrank(daoOwner);
    tinyDAO.doProposal(idRejected,description,yat,acceptedProposal,1);
    vm.stopPrank();

    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idRejected+1,description,yat,acceptedProposal,1);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    vm.expectRevert();
    tinyDAO.doProposal(idRejected+2,description,yat,acceptedProposal,1);
    vm.stopPrank();

    vm.startPrank(daoShareholder1);
    tinyDAO.vote(daoShareholder1, idRejected, TinyDAO.Votes.VoteAgainst);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    tinyDAO.vote(daoShareholder2, idRejected, TinyDAO.Votes.VoteAgainst);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idRejected));

    vm.startPrank(daoOwner);
    tinyDAO.doProposal(idRejected+100,description,yat,acceptedProposal,1);
    vm.stopPrank();
  }

  function testCanProposeTillTheLimit() public {
    vm.startPrank(daoOwner);
    tinyDAO.doProposal(idRejected,description,yat,acceptedProposal,1);
    vm.stopPrank();

    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idRejected+1,description,yat,acceptedProposal,1);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    vm.expectRevert();
    tinyDAO.doProposal(idRejected+2,description,yat,acceptedProposal,1);
    vm.stopPrank();
  }

  function testDoesGovernanceMattersForVote() public {
    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idAccepted,description,yat,acceptedProposal,1);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == false);
    vm.startPrank(daoShareholder1);
    vm.expectRevert();
    tinyDAO.executeProposal(idAccepted);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    tinyDAO.vote(daoShareholder2, idAccepted, TinyDAO.Votes.VoteFor);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == true);
  }

  function testCanReward() public {
    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idAccepted,description,yat,gainProposal,1);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == false);
    vm.startPrank(daoShareholder1);
    vm.expectRevert();
    tinyDAO.executeProposal(idAccepted);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    tinyDAO.vote(daoShareholder2, idAccepted, TinyDAO.Votes.VoteFor);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == true);

    vm.startPrank(daoShareholder1);
    uint baldaobefore = tinyDAO.getDaoGovernanceToken().balanceOf(daoShareholder1);
    tinyDAO.executeProposal(idAccepted);
    uint baldaoafter = tinyDAO.getDaoGovernanceToken().balanceOf(daoShareholder1);
    assert(baldaoafter > baldaobefore);
    vm.stopPrank();

  }
  function testCanPunish() public {
    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idAccepted,description,yat,acceptedProposal,1);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == false);
    vm.startPrank(daoShareholder1);
    vm.expectRevert();
    tinyDAO.executeProposal(idAccepted);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    tinyDAO.vote(daoShareholder2, idAccepted, TinyDAO.Votes.VoteFor);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == true);

    vm.startPrank(daoShareholder1);
    uint baldaobefore = tinyDAO.getDaoGovernanceToken().balanceOf(daoShareholder1);
    tinyDAO.executeProposal(idAccepted);
    uint baldaoafter = tinyDAO.getDaoGovernanceToken().balanceOf(daoShareholder1);
    assert(baldaobefore > baldaoafter);
    vm.stopPrank();
  }
  function testCanUpgrade() public {
    // checar se funciona o primeiro exatamente como esperado
    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idAccepted,description,yat,gainProposal,1);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == false);
    vm.startPrank(daoShareholder1);
    vm.expectRevert();
    tinyDAO.executeProposal(idAccepted);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    tinyDAO.vote(daoShareholder2, idAccepted, TinyDAO.Votes.VoteFor);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == true);

    vm.startPrank(daoShareholder1);
    uint baldaobefore = tinyDAO.getDaoGovernanceToken().balanceOf(daoShareholder1);
    uint balyatbefore = yat.balanceOf(daoShareholder1);
    tinyDAO.executeProposal(idAccepted);
    uint baldaoafter = tinyDAO.getDaoGovernanceToken().balanceOf(daoShareholder1);
    uint balyatafter = yat.balanceOf(daoShareholder1);
    assert(baldaoafter - baldaobefore == startingGainOffered);
    assert(balyatafter - balyatbefore == startingGainOffered * startingShare / 100);
    vm.stopPrank();

    // checar se tem update
    idAccepted += 1;
    uint newShare = 10;
    vm.startPrank(daoShareholder1);
    IDividendManager newDividendManager = new EqualDividendManager(address(tinyDAO), tinyDAO.getDaoGovernanceToken(), newShare);
    tinyDAO.doUpgradeProposal(idAccepted, description, newDividendManager);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == false);
    vm.startPrank(daoShareholder1);
    vm.expectRevert();
    tinyDAO.upgrade(idAccepted);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    tinyDAO.vote(daoShareholder2, idAccepted, TinyDAO.Votes.VoteFor);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == true);

    vm.startPrank(daoShareholder2);
    tinyDAO.upgrade(idAccepted);
    vm.stopPrank();

    // testar nova distribuicao
    idAccepted += 1;

    vm.startPrank(daoOwner);
    yat.approve(address(gainProposal), startingGainOffered);
    vm.stopPrank();

    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idAccepted,description,yat,gainProposal,1);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == false);

    vm.startPrank(daoShareholder1);
    vm.expectRevert();
    tinyDAO.executeProposal(idAccepted);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    tinyDAO.vote(daoShareholder2, idAccepted, TinyDAO.Votes.VoteFor);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == true);

    vm.startPrank(daoShareholder1);
    baldaobefore = tinyDAO.getDaoGovernanceToken().balanceOf(daoShareholder1);
    balyatbefore = yat.balanceOf(daoShareholder1);

    tinyDAO.executeProposal(idAccepted);

    baldaoafter = tinyDAO.getDaoGovernanceToken().balanceOf(daoShareholder1);
    balyatafter = yat.balanceOf(daoShareholder1);

    assert(baldaoafter - baldaobefore == startingGainOffered);
    assert(balyatafter - balyatbefore == startingGainOffered * newShare / 100);
    vm.stopPrank();
  }
}
