pragma solidity ^0.8.13;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import "src/IProposal.sol";
import "src/DaoGovernanceToken.sol";
import "src/EqualDividendManager.sol";

contract TinyDAO {
  DaoGovernanceToken daoGovernanceToken;
  enum Votes { NoVote, VoteFor, VoteAgainst }
  enum ProposalState { Proposed, Approved, Rejected, Done }

  event Proposed(uint256 id);
  event Approved(uint256 id);
  event Concluded(uint256 id);
  event Rejected(uint256 id);
  event Vote(uint256 id, address who, Votes vote);
  struct Proposal {
    uint256 id;
    address proposer;
    string description;
    ERC20 tokenType;
    uint256 amount;

    IProposal oneProposal;

    uint256 votesFor;
    uint256 votesAgainst;
    mapping (address => Votes) votesByAddress;

    ProposalState proposalState;

    bool isUpgrade;
    IDividendManager newDividendManager;
  }

  mapping(uint => Proposal) proposals;
  uint256 concurrentProposals;
  uint256 MAX_CONCURRENT_PROPOSALS;
  IDividendManager dividendManager;

  constructor (uint256 max_concurrent_proposals) {
    daoGovernanceToken = new DaoGovernanceToken("DaoGovernanceToken", "DGT");
    daoGovernanceToken.transfer(msg.sender, daoGovernanceToken.balanceOf(address(this)));
    concurrentProposals = 0;
    MAX_CONCURRENT_PROPOSALS = max_concurrent_proposals;
    dividendManager = new EqualDividendManager(address(this), daoGovernanceToken, 50);
  }

  function getDaoGovernanceToken() public view returns (DaoGovernanceToken) {
    return daoGovernanceToken;
  }

  function vote(address who, uint256 id, Votes voterVote) public {
    require(msg.sender == address(this) || msg.sender == who, "Somente o proprio ou o contrato vota");
    require(proposals[id].id != 0x0, "Proposta deve existir...");
    require(proposals[id].proposalState == ProposalState.Proposed, "Proposta deve estar em votacao...");
    uint256 votesCount = daoGovernanceToken.balanceOf(who);
    require(votesCount > 0, "Voce precisa de token para votar!");
    // retire se necessário
    if (proposals[id].votesByAddress[who] == Votes.VoteFor) {
      proposals[id].votesFor -= votesCount;
    } else if (proposals[id].votesByAddress[who] == Votes.VoteAgainst) {
      proposals[id].votesAgainst -= votesCount;
    }

    // incrementar o voto se necessário
    if (voterVote == Votes.VoteAgainst) {
      proposals[id].votesAgainst += votesCount;
    } else if (voterVote == Votes.VoteFor) {
      proposals[id].votesFor += votesCount;
    }

    emit Vote(id, who, voterVote);
  }

  function upgrade(uint256 id) public {
    require(proposals[id].isUpgrade, "Proposta nao e upgrade");
    require(proposals[id].id != 0x0, "Proposta deve existir...");
    require(proposals[id].proposalState == ProposalState.Approved, "Proposta deve estar aprovada...");
    proposals[id].proposalState = ProposalState.Done;
    emit Concluded(id);

    dividendManager = proposals[id].newDividendManager;
  }
  function executeProposal(uint256 id) public {
    require(proposals[id].isUpgrade == false, "Proposta e upgrade");
    require(proposals[id].id != 0x0, "Proposta deve existir...");
    require(proposals[id].proposalState == ProposalState.Approved, "Proposta deve estar aprovada...");
    proposals[id].proposalState = ProposalState.Done;
    emit Concluded(id);

    proposals[id].tokenType.approve(address(proposals[id].oneProposal),
                                    proposals[id].amount);
    proposals[id].oneProposal.executeProposal();
    proposals[id].oneProposal.distributeProfits(proposals[id].proposer, dividendManager);
  }

  function verifyVoted(uint256 id) public returns (bool) {
    require(proposals[id].id != 0x0, "Proposta deve existir...");
    uint256 daoTokenAmount = daoGovernanceToken.totalSupply();
    uint quorum = daoTokenAmount / 2;
    if (proposals[id].votesFor > quorum) {
      proposals[id].proposalState = ProposalState.Approved;
      concurrentProposals--;
      emit Approved(id);
      return true;
    }
    if (proposals[id].votesAgainst > quorum) {
      proposals[id].proposalState = ProposalState.Rejected;
      concurrentProposals--;
      emit Rejected(id);
      return true;
    }
    return false;
  }

  function doUpgradeProposal(uint256 id,
                             string memory description,
                             IDividendManager newDividendManager) public {
    require(daoGovernanceToken.balanceOf(msg.sender) > 0, "Apenas donos do token podem propor!");
    require(id != 0x0, "Proposta nao pode ser 0");
    require(proposals[id].id == 0x0, "Proposta ja existe");
    require(concurrentProposals < MAX_CONCURRENT_PROPOSALS, "Vote primeiro nas propostas existentes antes de exceder nosso limite!");
    proposals[id].id = id;
    proposals[id].description = description;
    proposals[id].votesFor = 0;
    proposals[id].votesAgainst = 0;
    proposals[id].proposer = msg.sender;
    proposals[id].proposalState = ProposalState.Proposed;
    proposals[id].isUpgrade = true;
    proposals[id].newDividendManager = newDividendManager;
    concurrentProposals++;

    emit Proposed(id);

    vote(msg.sender, id, Votes.VoteFor);
  }

  function doProposal(uint256 id,
                      string memory description,
                      ERC20 tokenType,
                      IProposal proposalContract,
                      uint256 amount) public {
    require(daoGovernanceToken.balanceOf(msg.sender) > 0, "Apenas donos do token podem propor!");
    require(id != 0x0, "Proposta nao pode ser 0");
    require(proposals[id].id == 0x0, "Proposta ja existe");
    require(concurrentProposals < MAX_CONCURRENT_PROPOSALS, "Vote primeiro nas propostas existentes antes de exceder nosso limite!");
    proposals[id].id = id;
    proposals[id].description = description;
    proposals[id].tokenType = tokenType;
    proposals[id].amount = amount;
    proposals[id].votesFor = 0;
    proposals[id].proposer = msg.sender;
    proposals[id].votesAgainst = 0;
    proposals[id].oneProposal = proposalContract;
    proposals[id].proposalState = ProposalState.Proposed;
    concurrentProposals++;

    emit Proposed(id);

    vote(msg.sender, id, Votes.VoteFor);
  }
}
