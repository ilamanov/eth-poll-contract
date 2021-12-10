// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract EthPoll {
    uint256 public totalPolls;
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

    event NewPoll(
        string indexed avatarUrl,
        string title,
        string about,
        uint256 createdTimestamp
    );

    constructor() {}

    function createPoll(
        string memory _avatarUrl,
        string memory _title,
        string memory _about
    ) public {
        require(
            !polls[msg.sender].isActive,
            "This address already contains a poll. Use overwriteWithNewPoll() instead"
        );
        totalPolls++;
        polls[msg.sender].isActive = true;
        overwriteWithNewPoll(_avatarUrl, _title, _about);
    }

    function overwriteWithNewPoll(
        string memory _avatarUrl,
        string memory _title,
        string memory _about
    ) public {
        require(
            polls[msg.sender].isActive,
            "This address does not have a poll. Use createPoll() instead"
        );
        Poll storage poll = polls[msg.sender];
        poll.avatarUrl = _avatarUrl;
        poll.title = _title;
        poll.about = _about;
        poll.createdTimestamp = block.timestamp;
        delete poll.proposals;

        emit NewPoll(_avatarUrl, _title, _about, block.timestamp);
    }

    function editPoll(
        string memory _avatarUrl,
        string memory _title,
        string memory _about
    ) public {
        require(
            polls[msg.sender].isActive,
            "This address does not have a poll. Use createPoll()."
        );
        polls[msg.sender].avatarUrl = _avatarUrl;
        polls[msg.sender].title = _title;
        polls[msg.sender].about = _about;
    }

    function propose(address _pollOwnerAddress, string memory _title) public {
        require(
            polls[_pollOwnerAddress].isActive,
            "There is no poll belonging to this address"
        );
        Proposal memory proposal;
        proposal.title = _title;
        proposal.createdBy = msg.sender;

        polls[_pollOwnerAddress].proposals.push(proposal);
    }

    function upvote(address _pollOwnerAddress, uint256 _proposalIndex) public {
        require(
            polls[_pollOwnerAddress].isActive,
            "There is no poll belonging to this address"
        );
        require(
            _proposalIndex >= 0 &&
                _proposalIndex < polls[_pollOwnerAddress].proposals.length,
            "This proposal does not exist"
        );

        polls[_pollOwnerAddress].proposals[_proposalIndex].upvotes.push(
            msg.sender
        );
    }

    function downvote(address _pollOwnerAddress, uint256 _proposalIndex)
        public
    {
        require(
            polls[_pollOwnerAddress].isActive,
            "There is no poll belonging to this address"
        );
        require(
            _proposalIndex >= 0 &&
                _proposalIndex < polls[_pollOwnerAddress].proposals.length,
            "This proposal does not exist"
        );

        polls[_pollOwnerAddress].proposals[_proposalIndex].downvotes.push(
            msg.sender
        );
    }

    function getProposalCount(address _pollOwnerAddress)
        public
        view
        returns (uint256 count)
    {
        require(
            polls[_pollOwnerAddress].isActive,
            "There is no poll belonging to this address"
        );
        return polls[_pollOwnerAddress].proposals.length;
    }

    function getProposal(address _pollOwnerAddress, uint256 _proposalIndex)
        public
        view
        returns (Proposal memory)
    {
        require(
            polls[_pollOwnerAddress].isActive,
            "There is no poll belonging to this address"
        );
        require(
            _proposalIndex >= 0 &&
                _proposalIndex < polls[_pollOwnerAddress].proposals.length,
            "This proposal does not exist"
        );
        return polls[_pollOwnerAddress].proposals[_proposalIndex];
    }
}
