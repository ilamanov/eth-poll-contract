// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract DePoll {
    uint256 constant PROPOSE_COST = 0.0025 ether;
    uint256 constant UPVOTE_COST = 0.00025 ether;
    uint256 constant DOWNVOTE_COST = 0.0005 ether;
    uint256 constant PROPOSAL_PAYOUT_FACTOR = 10;
    uint256 constant UPVOTE_PAYOUT_FACTOR = 1;

    mapping(address => Poll) public polls;

    struct Poll {
        bool isActive;
        string avatarUrl;
        string title;
        string about;
        uint256 createdTimestamp;
        Proposal[] proposals;
        uint256[] cycleCutoffs;
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

    function propose(address _pollOwnerAddress, string memory _title)
        public
        payable
    {
        require(msg.value == PROPOSE_COST, "invalid amount supplied");
        Proposal memory proposal;
        proposal.title = _title;
        proposal.createdBy = msg.sender;

        polls[_pollOwnerAddress].proposals.push(proposal);
    }

    function upvote(address _pollOwnerAddress, uint256 _proposalIndex)
        public
        payable
    {
        require(msg.value == UPVOTE_COST, "invalid amount supplied");
        polls[_pollOwnerAddress].proposals[_proposalIndex].upvotes.push(
            msg.sender
        );
    }

    function downvote(address _pollOwnerAddress, uint256 _proposalIndex)
        public
        payable
    {
        require(msg.value == DOWNVOTE_COST, "invalid amount supplied");
        polls[_pollOwnerAddress].proposals[_proposalIndex].downvotes.push(
            msg.sender
        );
    }

    function endCycle() public {
        address pollOwnerAddress = msg.sender;
        uint256 cycleIndex = polls[msg.sender].cycleCutoffs.length;

        uint256[] memory proposalRange = getProposalRange(
            pollOwnerAddress,
            cycleIndex
        );

        require(
            proposalRange[0] < proposalRange[1],
            "There are no new proposals"
        );

        uint256 cycleTotal = getTotalContributed(
            pollOwnerAddress,
            proposalRange[0],
            proposalRange[1]
        );

        uint256[] memory winningProposalIdxs = getWinningProposals(
            pollOwnerAddress,
            proposalRange[0],
            proposalRange[1]
        );
        uint256 numberOfWinners = winningProposalIdxs.length;

        uint256 cycleTotalShares = 0;
        for (uint256 i = 0; i < numberOfWinners; i++) {
            Proposal memory winningProposal = polls[pollOwnerAddress].proposals[
                winningProposalIdxs[i]
            ];
            cycleTotalShares += PROPOSAL_PAYOUT_FACTOR;
            cycleTotalShares += (winningProposal.upvotes.length *
                UPVOTE_PAYOUT_FACTOR);
        }

        uint256 share = cycleTotal / cycleTotalShares;
        uint256 change = cycleTotal - (share * cycleTotalShares);
        for (uint256 i = 0; i < numberOfWinners; i++) {
            Proposal memory winningProposal = polls[pollOwnerAddress].proposals[
                winningProposalIdxs[i]
            ];

            uint256 value = share * PROPOSAL_PAYOUT_FACTOR;
            if (i == 0) {
                // first winning proposal gets the change
                value += change;
            }
            (bool success, ) = payable(winningProposal.createdBy).call{
                value: value
            }("");
            require(success, "Failed to send Ether");

            for (uint256 j = 0; j < winningProposal.upvotes.length; j++) {
                (bool success2, ) = payable(winningProposal.upvotes[j]).call{
                    value: share * UPVOTE_PAYOUT_FACTOR
                }("");
                require(success2, "Failed to send Ether");
            }
        }

        polls[pollOwnerAddress].cycleCutoffs.push(
            polls[pollOwnerAddress].proposals.length
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

    function getProposalRange(address _pollOwnerAddress, uint256 _cycleIndex)
        public
        view
        returns (uint256[] memory proposalRange)
    {
        Poll memory poll = polls[_pollOwnerAddress];
        Proposal[] memory proposals = poll.proposals;
        uint256[] memory cycleCutoffs = poll.cycleCutoffs;

        uint256 startIdx = 0;
        if (_cycleIndex > 0) {
            startIdx = cycleCutoffs[_cycleIndex - 1];
        }
        uint256 cutoff = proposals.length;
        if (_cycleIndex < cycleCutoffs.length) {
            cutoff = cycleCutoffs[_cycleIndex];
        }

        uint256[] memory range = new uint256[](2);
        range[0] = startIdx;
        range[1] = cutoff;
        return range;
    }

    function getTotalContributed(
        address _pollOwnerAddress,
        uint256 _startIdx,
        uint256 _cutoff
    ) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = _startIdx; i < _cutoff; i++) {
            Proposal memory proposal = polls[_pollOwnerAddress].proposals[i];
            total += PROPOSE_COST;
            total += (proposal.upvotes.length * UPVOTE_COST);
            total += (proposal.downvotes.length * DOWNVOTE_COST);
        }
        return total;
    }

    function getWinningProposals(
        address _pollOwnerAddress,
        uint256 _startIdx,
        uint256 _cutoff
    ) public view returns (uint256[] memory proposalIdxs) {
        int256 maxVotes = -1000;
        uint256[] memory winningProposalIdxs = new uint256[](5);
        uint256 numberOfWinners = 0;

        for (uint256 i = _startIdx; i < _cutoff; i++) {
            Proposal memory proposal = polls[_pollOwnerAddress].proposals[i];
            int256 votes = int256(proposal.upvotes.length) -
                int256(proposal.downvotes.length);
            if (votes > maxVotes) {
                maxVotes = votes;
                winningProposalIdxs = new uint256[](5);
                winningProposalIdxs[0] = i;
                numberOfWinners = 1;
            } else if (votes == maxVotes) {
                winningProposalIdxs[numberOfWinners] = i;
                numberOfWinners++;
            }
        }

        uint256[] memory result = new uint256[](numberOfWinners);
        for (uint256 i = 0; i < numberOfWinners; i++) {
            result[i] = winningProposalIdxs[i];
        }
        return result;
    }
}
