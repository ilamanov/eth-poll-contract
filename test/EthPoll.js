const { ethers } = require("hardhat");
const { expect } = require("chai");

function checkIfPollIsUndefined(poll) {
  expect(poll.isActive).to.equal(false);
  expect(poll.avatarUrl).to.equal("");
}

describe("mocha before hooks", function () {
  before(() => console.log("*** top-level before()"));
  beforeEach(() => console.log("*** top-level beforeEach()"));
  it("is outer spec", () => true);
  describe("nesting", function () {
    before(() => console.log("*** nested before()"));
    beforeEach(() => console.log("*** nested beforeEach()"));
    it("is a nested spec", () => true);
  });
});

// https://hardhat.org/tutorial/testing-contracts.html
describe("EthPoll contract", function () {
  let pollContractFactory;
  let pollContract;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    pollContractFactory = await ethers.getContractFactory("EthPoll");
    pollContract = await pollContractFactory.deploy();
    await pollContract.deployed();
  });

  describe("Deployment", function () {
    it("Should start with 0 polls", async function () {
      expect(await pollContract.totalPolls()).to.equal(
        ethers.BigNumber.from("0")
      );
    });

    it("Should start with empty poll mapping", async function () {
      checkIfPollIsUndefined(await pollContract.polls(owner.address));
      checkIfPollIsUndefined(await pollContract.polls(addr1.address));
      checkIfPollIsUndefined(await pollContract.polls(addr2.address));
    });
  });

  describe("Creating a Poll", function () {
    let avatarUrl, title, bio;

    beforeEach(async function () {
      avatarUrl = "https://eth-poll.s3.amazonaws.com/avatar.jpeg";
      title = "👋 Hey, this is Nazar";
      bio = "Let me know what web3 concept you would like me to explain!";

      const createPollTxn = await pollContract.createPoll(
        avatarUrl,
        title,
        bio
      );
      await createPollTxn.wait(); // Wait for the transaction to be mined
    });

    it("Should have 1 total polls", async function () {
      expect(await pollContract.totalPolls()).to.equal(
        ethers.BigNumber.from("1")
      );
    });

    it("Should correctly set Poll params", async function () {
      const poll = await pollContract.polls(owner.address);
      expect(poll.isActive).to.equal(true);
      expect(poll.avatarUrl).to.equal(avatarUrl);
      expect(poll.title).to.equal(title);
      expect(poll.bio).to.equal(bio);
      expect(poll.proposals).to.equal(undefined);
    });

    it("Should not allow to create again", async function () {
      try {
        const createPollTxn2 = await pollContract.createPoll(
          avatarUrl,
          title,
          bio
        );
        await createPollTxn2.wait(); // Wait for the transaction to be mined
      } catch (error) {
        expect(!!error).to.equal(true);
      }
    });
  });

  // TODO
  describe("Editing Poll", function () {});

  describe("Proposal", function () {
    let avatarUrl, title, bio, proposalTitle;

    beforeEach(async function () {
      avatarUrl = "https://eth-poll.s3.amazonaws.com/avatar.jpeg";
      title = "👋 Hey, this is Nazar";
      bio = "Let me know what web3 concept you would like me to explain!";

      const createPollTxn = await pollContract.createPoll(
        avatarUrl,
        title,
        bio
      );
      await createPollTxn.wait(); // Wait for the transaction to be mined

      proposalTitle = "Let's talk about Solidity";

      const proposeTxn = await pollContract
        .connect(addr2)
        .propose(owner.address, proposalTitle);
      await proposeTxn.wait();
    });

    it("Should correctly submit a proposal", async function () {
      expect(await pollContract.getProposalCount(owner.address)).to.equal(1);
      const proposal = await pollContract.getProposal(owner.address, 0);
      expect(proposal.title).to.equal(proposalTitle);
      expect(proposal.createdBy).to.equal(addr2.address);
      expect(proposal.upvotes.length).to.equal(0);
      expect(proposal.downvotes.length).to.equal(0);
    });

    it("Should correctly upvote", async function () {
      const upvoteTxn = await pollContract
        .connect(addr3)
        .upvote(owner.address, 0);
      await upvoteTxn.wait();

      expect(await pollContract.getProposalCount(owner.address)).to.equal(1);
      const proposal = await pollContract.getProposal(owner.address, 0);
      expect(proposal.title).to.equal(proposalTitle);
      expect(proposal.createdBy).to.equal(addr2.address);
      expect(proposal.upvotes.length).to.equal(1);
      expect(proposal.upvotes[0]).to.equal(addr3.address);
      expect(proposal.downvotes.length).to.equal(0);
    });
  });

  // TODO
  describe("Overwriting Poll", function () {});
});
