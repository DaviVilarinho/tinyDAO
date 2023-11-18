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
    yat = new YetAnotherToken(); // criar token dummy para usar
    acceptedProposal = new YetAnotherLossyProposal(yat); // proposta que sera aceita (sempre perde)
    gainProposal = new YetAnotherGainProposal(yat); // proposta que o daoowner doa pro contrato dinheiro...
    yat.approve(address(gainProposal), startingGainOffered); // permite o contrato que doa ter o dinheiro
    tinyDAO = new TinyDAO(MAX_CONCURRENT_PROPOSALS); // cria dao com 2 propostas como cap
    // so dando governance tokens pros outros
    tinyDAO.getDaoGovernanceToken().transfer(daoShareholder1, BASE_SHAREHOLDERS_AMOUNT); 
    tinyDAO.getDaoGovernanceToken().transfer(daoShareholder2, BASE_SHAREHOLDERS_AMOUNT);
    // da um pouquinho de yat pro tinydao pra facilitar meus trabalhos
    yat.transfer(address(tinyDAO), 5000);
    vm.stopPrank();
  }

  uint idAccepted = 1;
  uint idRejected = 999;
  string description = "aceitar";

  function testCanCreateProposal() public {
    vm.expectRevert(); // n pode quem n tem token
    tinyDAO.doProposal(idAccepted,description,yat,acceptedProposal,1);

    vm.startPrank(daoOwner); // quem tem token pode propor
    tinyDAO.doProposal(idAccepted,description,yat,acceptedProposal,1);
    vm.stopPrank();
  }

  function testCanProposeAgainWhenVotedAndAtLimitBefore() public {
    vm.startPrank(daoOwner);
    tinyDAO.doProposal(idRejected,description,yat,acceptedProposal,1); // propoe uma
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    vm.expectRevert();
    tinyDAO.doProposal(idRejected,description,yat,acceptedProposal,1); // propos igual nao pode!
    vm.stopPrank();

    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idRejected+1,description,yat,acceptedProposal,1); // propo duas
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    vm.expectRevert();
    tinyDAO.doProposal(idRejected+2,description,yat,acceptedProposal,1); // bate no limite!
    vm.stopPrank();

    // rejeitar proposta para ver se reseta o cap
    vm.startPrank(daoShareholder1);
    tinyDAO.vote(daoShareholder1, idRejected, TinyDAO.Votes.VoteAgainst);
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    tinyDAO.vote(daoShareholder2, idRejected, TinyDAO.Votes.VoteAgainst);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idRejected));

    vm.startPrank(daoOwner);
    tinyDAO.doProposal(idRejected+100,description,yat,acceptedProposal,1); // cap resetado!
    vm.stopPrank();
  }

  function testCanProposeTillTheLimit() public {
    vm.startPrank(daoOwner);
    tinyDAO.doProposal(idRejected,description,yat,acceptedProposal,1); // propoe 1
    vm.stopPrank();

    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idRejected+1,description,yat,acceptedProposal,1); // propoe 2
    vm.stopPrank();

    vm.startPrank(daoShareholder2);
    vm.expectRevert();
    tinyDAO.doProposal(idRejected+2,description,yat,acceptedProposal,1); // rejeita, bateu no limite concorrencia!
    vm.stopPrank();
  }

  function testDoesGovernanceMattersForVote() public {
    vm.startPrank(daoShareholder1);
    tinyDAO.doProposal(idAccepted,description,yat,acceptedProposal,1);
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == false);
    vm.startPrank(daoShareholder1);
    vm.expectRevert();
    tinyDAO.executeProposal(idAccepted); // sem quorum suficiente para executar
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == false); // confirmando sem quorum

    vm.startPrank(daoShareholder2);
    tinyDAO.vote(daoShareholder2, idAccepted, TinyDAO.Votes.VoteFor); // vota primeiro
    vm.stopPrank();

    assert(tinyDAO.verifyVoted(idAccepted) == true); // tem quorum suficiente!
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
    tinyDAO.executeProposal(idAccepted); // se passar
    uint baldaoafter = tinyDAO.getDaoGovernanceToken().balanceOf(daoShareholder1);
    assert(baldaoafter > baldaobefore); // recompensar em DaoTokens quem ajudou a DAO
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
    assert(baldaobefore > baldaoafter); // penalizar em DaoGovernanceTokens quem sugeriu coisa ruim
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
    assert(baldaoafter - baldaobefore == startingGainOffered); // checa ganho em DaoGovernanceToken
    assert(balyatafter - balyatbefore == startingGainOffered * startingShare / 100); // checa ganho em tokens usados
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
    tinyDAO.upgrade(idAccepted); // faz upgrade
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

    assert(baldaoafter - baldaobefore == startingGainOffered); // ganha tokens de governança
    assert(balyatafter - balyatbefore == startingGainOffered * newShare / 100); // muda recompensa
    vm.stopPrank();
  }
}
