// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract DePoll {
    mapping(address => Poll) public polls;

    struct Poll {
        bool isActive;
        string avatarUrl;
        string title;
        string about;
        uint256 createdTimestamp;
        Proposal[] proposals;
    }

    struct Proposal {
        string title;
        address createdBy;
        address[] upvotes;
        address[] downvotes;
    }

    constructor() {}

    function createPoll(
        string memory _avatarUrl,
        string memory _title,
        string memory _about
    ) public {
        Poll storage poll = polls[msg.sender];
        poll.isActive = true;
        poll.avatarUrl = _avatarUrl;
        poll.title = _title;
        poll.about = _about;
        poll.createdTimestamp = block.timestamp;
        delete poll.proposals;
    }

    function editPoll(
        string memory _avatarUrl,
        string memory _title,
        string memory _about
    ) public {
        polls[msg.sender].avatarUrl = _avatarUrl;
        polls[msg.sender].title = _title;
        polls[msg.sender].about = _about;
    }

    function propose(address _pollOwnerAddress, string memory _title) public {
        Proposal memory proposal;
        proposal.title = _title;
        proposal.createdBy = msg.sender;

        polls[_pollOwnerAddress].proposals.push(proposal);
    }

    function upvote(address _pollOwnerAddress, uint256 _proposalIndex) public {
        polls[_pollOwnerAddress].proposals[_proposalIndex].upvotes.push(
            msg.sender
        );
    }

    function downvote(address _pollOwnerAddress, uint256 _proposalIndex)
        public
    {
        polls[_pollOwnerAddress].proposals[_proposalIndex].downvotes.push(
            msg.sender
        );
    }

    function getProposalCount(address _pollOwnerAddress)
        public
        view
        returns (uint256 count)
    {
        return polls[_pollOwnerAddress].proposals.length;
    }

    function getProposal(address _pollOwnerAddress, uint256 _proposalIndex)
        public
        view
        returns (Proposal memory)
    {
        return polls[_pollOwnerAddress].proposals[_proposalIndex];
    }
}
