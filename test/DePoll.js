const { ethers } = require("hardhat");
const { expect } = require("chai");

function checkIfPollIsUndefined(poll) {
  expect(poll.isActive).to.equal(false);
  expect(poll.avatarUrl).to.equal("");
}

// https://hardhat.org/tutorial/testing-contracts.html
describe("DePoll contract", function () {
  let contract;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    const contractFactory = await ethers.getContractFactory("DePoll");
    contract = await contractFactory.deploy();
    await contract.deployed();
  });

  describe("Deployment", function () {
    it("Should start with empty poll mapping", async function () {
      checkIfPollIsUndefined(await contract.polls(owner.address));
      checkIfPollIsUndefined(await contract.polls(addr1.address));
      checkIfPollIsUndefined(await contract.polls(addr2.address));
    });
  });

  describe("Creating a Poll", function () {
    let avatarUrl, title, about;

    beforeEach(async function () {
      avatarUrl = "https://eth-poll.s3.amazonaws.com/avatar.jpeg";
      title = "👋 Hey, this is Nazar";
      about = "Let me know what web3 concept you would like me to explain!";

      const createPollTxn = await contract.createPoll(avatarUrl, title, about);
      await createPollTxn.wait(); // Wait for the transaction to be mined
    });

    it("Should correctly set Poll params", async function () {
      const pollOwnerAddress = owner.address;
      const poll = await contract.polls(pollOwnerAddress);
      expect(poll.isActive).to.equal(true);
      expect(poll.avatarUrl).to.equal(avatarUrl);
      expect(poll.title).to.equal(title);
      expect(poll.about).to.equal(about);
      expect(
        Object.keys(contract.getProposalCount(pollOwnerAddress)).length
      ).to.equal(0);
    });

    describe("Edit Poll", function () {
      it("Should correctly edit afterwards", async function () {
        const avatarUrl2 = "2https://eth-poll.s3.amazonaws.com/avatar.jpeg";
        const title2 = "2👋 Hey, this is Nazar";
        const about2 =
          "2Let me know what web3 concept you would like me to explain!";

        const editPollTxn = await contract.editPoll(avatarUrl2, title2, about2);
        await editPollTxn.wait(); // Wait for the transaction to be mined

        const pollOwnerAddress = owner.address;
        const poll = await contract.polls(pollOwnerAddress);
        expect(poll.isActive).to.equal(true);
        expect(poll.avatarUrl).to.equal(avatarUrl2);
        expect(poll.title).to.equal(title2);
        expect(poll.about).to.equal(about2);

        expect(
          Object.keys(contract.getProposalCount(pollOwnerAddress)).length
        ).to.equal(0);
      });
    });

    describe("Proposal", function () {
      let proposalTitle;

      beforeEach(async function () {
        proposalTitle = "Let's talk about Solidity";

        const proposeTxn = await contract
          .connect(addr2)
          .propose(owner.address, proposalTitle);
        await proposeTxn.wait();
      });

      it("Should correctly submit a proposal", async function () {
        expect(await contract.getProposalCount(owner.address)).to.equal(
          ethers.BigNumber.from("1")
        );
        const proposal = await contract.getProposal(owner.address, 0);
        expect(proposal.title).to.equal(proposalTitle);
        expect(proposal.createdBy).to.equal(addr2.address);
        expect(proposal.upvotes.length).to.equal(0);
        expect(proposal.downvotes.length).to.equal(0);
      });

      describe("Voting", function () {
        it("Should correctly upvote", async function () {
          const upvoteTxn = await contract
            .connect(addr3)
            .upvote(owner.address, 0);
          await upvoteTxn.wait();

          expect(await contract.getProposalCount(owner.address)).to.equal(
            ethers.BigNumber.from("1")
          );
          const proposal = await contract.getProposal(owner.address, 0);
          expect(proposal.title).to.equal(proposalTitle);
          expect(proposal.createdBy).to.equal(addr2.address);
          expect(proposal.upvotes.length).to.equal(1);
          expect(proposal.upvotes[0]).to.equal(addr3.address);
          expect(proposal.downvotes.length).to.equal(0);
        });
      });
    });
  });
});
