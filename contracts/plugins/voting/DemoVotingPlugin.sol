// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../IAutID.sol";
import "../../modules/voting/VotingModule.sol";
import "../../daoUtils/interfaces/get/IDAOAdmin.sol";
import "../../daoUtils/interfaces/get/IAutIDAddress.sol";
import "../SimplePlugin.sol";

// feature idea -- create a proposal pipline configurator (multi-stage proposal) 

// warning: this is a straight-forward inefficient demo version. do not use in production
//
// 1/ use `bytes32` instead of `bytes` for storing IPFS hashes (multihash standard)
//    in order to save 1 storage slot
//
// 2/ use ordered structs (https://ethereum-grove.readthedocs.io/en/latest/api.html) or similar
//    for storing proposals (ordered data structures)
//    another example: https://github.com/MihanixA/SummingPriorityQueue
//
// 3/ `getActiveProposalsIDs()` approach may lead to block gas limit
//    consider using `getActiveProposalNumber()` along with `getActiveProposalAt(uint256 i)`
//    instead
//

contract DemoVotingPlugin is SimplePlugin, VotingModule {

    uint256 public constant CREATE_PROPOSAL_MEMBER_COOLDOWN_SECONDS = 3600;
    uint256 public constant PROPOSAL_NUM_THRESHOLD = 20_000;
    uint256 public constant override ACTIVE_PROPOSAL_NUM_THRESHOLD = PROPOSAL_NUM_THRESHOLD;

    uint256 public constant ROLE_1_WEIGHT = 10;
    uint256 public constant ROLE_2_WEIGHT = 21;
    uint256 public constant ROLE_3_WEIGHT = 18;


    mapping(uint256 => int256) internal _votingScore;
    mapping(uint256 => mapping(address => bool)) internal _hasVoted;
    mapping(address => uint256) internal _lastProposalCreatedAt;
    Proposal[] internal _proposals;

    /**
     * @dev Initializes a new `QuestOnboardingPlugin` instance.
     * @param dao The DAO address.
     */
    constructor(address dao) SimplePlugin(dao, 0) {
        _setActive(true);
    }

    function getVotingScore(uint256 proposalId) external view override returns(int256) {
        return _votingScore[proposalId];
    }

    function getProposal(uint256 proposalId) external view override returns(Proposal memory) {
        return _proposals[proposalId];
    }

    function getActiveProposalIDs() external view override returns(uint256[] memory) {
        uint256 length = _proposals.length;
        uint256[] memory ids = new uint256[](length);
        uint256 ptr;
        for (uint256 i; i != length; ++i) {
            if (_isActiveProposal(i)) {
                ids[ptr] = i;
                ++ptr;
            }
        }
        uint256[] memory result = new uint256[](ptr);
        for (uint256 i; i != ids.length; ++i) {
            result[i] = ids[i];
        }
        return result;
    }

    /// @dev create a proposal :) 
    function createProposal(
        uint128 beginTs,
        uint128 endTs,
        bytes memory metadataCID
    ) external override {
        _validateProposal(beginTs, endTs);
        require(_getMemberWeight() > 0, "not a member");
        require(
            block.timestamp >= _lastProposalCreatedAt[msg.sender] + CREATE_PROPOSAL_MEMBER_COOLDOWN_SECONDS,
            "cooldown"
        );
        _lastProposalCreatedAt[msg.sender] = block.timestamp;    
        Proposal memory newProposal;
        newProposal.beginTs = beginTs;
        newProposal.endTs = endTs;
        newProposal.metadataCID = metadataCID;
        _proposals.push(newProposal);
        emit ProposalCreated(msg.sender, daoAddress(), _proposals.length - 1);
    }

    /// @dev vote on the given proposal
    function vote(uint256 proposalId, bool isUpvote) external override {
        require(_isActiveProposal(proposalId), "proposal not active");
        require(!_hasVoted[proposalId][msg.sender], "member has voted");
        _hasVoted[proposalId][msg.sender] = true;
        int256 weight = int256(_getMemberWeight());
        if (isUpvote) {
            _votingScore[proposalId] += weight;
            emit Voted(msg.sender, daoAddress(), proposalId, weight);
        } else {
            _votingScore[proposalId] -= weight;
            emit Voted(msg.sender, daoAddress(), proposalId, -weight);
        }
    }

    /// @dev next (autoincrement) proposal id 
    function nextProposalId() public view override returns(uint256) {
        return _proposals.length;
    }

    /// @dev verify if the given proposal is active at this time
    function _isActiveProposal(uint256 proposalId) internal view returns(bool) {
        Proposal memory p = _proposals[proposalId];
        return p.beginTs <= block.timestamp && block.timestamp <= p.endTs;
    }

    /// @dev get member's vote weight (zero if user isn't a member)
    function _getMemberWeight() internal view returns(uint256) {
        IAutID.DAOMember memory m;
        m = IAutID(IAutIDAddress(daoAddress()).getAutIDAddress()).getMembershipData(msg.sender, daoAddress());
        if (!m.isActive) {
            return 0; // not a member
        } else if (m.role == 1) {
            return ROLE_1_WEIGHT;
        } else if (m.role == 2) {
            return ROLE_2_WEIGHT;
        } else if (m.role == 3) {
            return ROLE_3_WEIGHT;
        } else {
            revert("invariant"); // 0 < x < 4 by invariant
        }
    }

    /// @dev validate proposal timestamps to be valid
    function _validateProposal(uint128 beginTs, uint128 endTs) internal view {
        require(
            beginTs >= block.timestamp && beginTs < endTs,
            "timestamps are invalid"
        );
        require(_proposals.length < PROPOSAL_NUM_THRESHOLD, "max proposal threshold reached");
        // todo: use blocks instead of timestamps;
        // todo: use begin&duration instead of begin&end 
        // todo: add a min+max threshold for proposal's lifespan
    }
}
