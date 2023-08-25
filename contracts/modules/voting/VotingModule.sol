//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../IModule.sol";
/* 
The VotingModule 
*/

interface VotingModule is IModule {
    // emitted when a member has voted
    event Voted(address member, address dao, uint256 proposalId, int256 weightedDiff);
    event ProposalCreated(address member, address dao, uint256 proposalId);

    // tho it's better to use block.number instead of raw timestamp
    struct Proposal {
        uint128 beginTs;
        uint128 endTs;
        bytes metadataCID;
    }

    // max number open votings at the any given moment in time 
    // it's needed because we have a mandatory `getActiveProposalIDs` below,
    // which could result in block-gas-limit error if no threshold set
    function ACTIVE_PROPOSAL_NUM_THRESHOLD() external view returns(uint256);

    // get proposal details
    function getProposal(uint256 proposalId) external view returns(Proposal memory);

    // get ids of the proposal with ongoing voting
    // fixme: this interface design may be suboptimal 
    // (see comment above on `ACTIVE_PROPOSAL_NUM_THRESHOLD`)
    function getActiveProposalIDs() external view returns(uint256[] memory);

    // get voting results
    function getVotingScore(uint256 proposalId) external view returns(int256);

    // get next proposal id (autoincrement)
    function nextProposalId() external view returns(uint256);

    // vote on the proposal
    function vote(uint256 proposalId, bool isUpvote) external;

    // create a proposal (member-only)
    function createProposal(uint128 beginTs, uint128 endTs, bytes memory metadataCID) external;
}
