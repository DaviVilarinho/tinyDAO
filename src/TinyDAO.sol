pragma solidity ^0.8.13;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import "IProposal.sol"
import "DaoGovernanceToken.sol"

contract TinyDAO {
  ERC20 daoGovernanceToken;
  enum Votes { NoVote, VoteFor, VoteAgainst };
  enum ProposalState { Proposed, Approved, Rejected, Done };

  event Proposed(uint256 id);
  event Approved(uint256 id);
  event Concluded(uint256 id);
  event Rejected(uint256 id);
  event Vote(uint256 id, address who, Votes vote);
  event Rewarded(uint256 id, address who, uint daoTokens);
  event Punished(uint256 id, address who, uint daoTokens);

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
  }

  mapping(id => Proposal) proposals;
  uint256 concurrentProposals;
  uint256 MAX_CONCURRENT_PROPOSALS;

  constructor (uint256 max_concurrent_proposals) {
    daoGovernanceToken = new DaoGovernanceToken();
    concurrentProposals = 0;
    MAX_CONCURRENT_PROPOSALS = max_concurrent_proposals;
  }

  function vote(address who, uint256 id, Votes vote) public {
    require(proposals[id].id != 0x0, "Proposta deve existir...");
    require(proposals[id].proposalState == ProposalState.Proposed, "Proposta deve estar em votação...");
    uint256 votesCount = daoGovernanceToken.balanceOf(who);
    require(votesCount > 0, "Voce precisa de token para votar!");
    // retire se necessário
    if (proposals[id].votesByAddress[who] == Votes.VoteFor) {
      proposals[id].votesFor -= votesCount;
    } else if (proposals[id].votesByAddress[who] == Votes.VoteAgainst) {
      proposals[id].votesAgainst -= votesCount;
    }

    // incrementar o voto se necessário
    if (vote == Votes.VoteAgainst) {
      proposals[id].votesAgainst += votesCount;
    } else if (vote == Votes.VoteFor) {
      proposals[id].votesFor += votesCount;
    }

    emit Vote(id, who, vote);
  }

  function executeProposal(uint256 id) public {
    require(proposals[id].id != 0x0, "Proposta deve existir...");
    require(proposals[id].proposalState == ProposalState.Approved, "Proposta deve estar aprovada...");
    concurrentProposals--;
    proposals[id].proposalState = ProposalState.Done;
    emit Concluded(id);

    uint balanceBefore = proposals[id].tokenType.balanceOf(address(this));
    proposals[id].tokenType.allow(address(proposals[id].oneProposal),
                                  proposals[id].amount);
    proposals[id].oneProposal.executeProposal();

    uint balanceAfter = proposals[id].tokenType.balanceOf(address(this));
    int profit = balanceAfter - balanceBefore;
    if (profit >= 0) {
      emit Rewarded(id, proposals[id].proposer, profit);
      daoGovernanceToken.reward(proposals[id].proposer, profit);
    } else {
      emit Punished(id, proposals[id].proposer, profit);
      daoGovernanceToken.punish(proposals[id].proposer, profit);
    }
  }

  function verifyVoted(uint256 id) public bool {
    require(proposals[id].id != 0x0, "Proposta deve existir...");
    uint256 daoTokenAmount = daoGovernanceToken.totalSupply();
    if (proposals[id].votesFor > daoTokenAmount / 2) {
      proposals[id].proposalState = ProposalState.Approved;
      emit Approved(id);
      return true;
    }
    if (proposals[id].votesAgainst > daoTokenAmount / 2) {
      proposals[id].proposalState = ProposalState.Rejected;
      emit Rejected(id);
      return true;
    }
    return false;
  }

  function doProposal(uint256 id,
                      string description,
                      ERC20 tokenType,
                      uint256 amount) public {
    require(daoGovernanceToken.balanceOf(msg.sender) > 0), "Apenas donos do token podem propor!");
    require(proposals[id] == 0x0, "Proposta ja existe");
    require(concurrentProposals < MAX_CONCURRENT_PROPOSALS, "Vote primeiro nas propostas existentes antes de exceder nosso limite!");
    Proposal storage newProposal;
    newProposal.id = id;
    newProposal.description = description;
    newProposal.tokenType = tokenType;
    newProposal.amount = amount;
    newProposal.votesFor = 0;
    newProposal.votesAgainst = 0;
    newProposal.proposalState = ProposalState.Proposed;
    proposals[id] = newProposal;
    concurrentProposals++;

    emit Proposed(id);

    vote(msg.sender, id, Votes.VoteFor);
  }


}
