const main = async () => {
  const [owner, randomPerson] = await hre.ethers.getSigners();

  const pollContractFactory = await hre.ethers.getContractFactory("EthPoll");
  const pollContract = await pollContractFactory.deploy();
  await pollContract.deployed();
  console.log("Contract deployed to:", pollContract.address);

  console.log("pollCount", await pollContract.totalPolls());

  await (
    await pollContract.createPoll(
      "https://eth-poll.s3.amazonaws.com/avatar.jpeg",
      "👋 Hey, this is Nazar",
      "Let me know what web3 concept you would like me to explain!"
    )
  ).wait(); // Wait for the transaction to be mined
  console.log("created poll", await pollContract.polls(owner.address));
  console.log("pollCount2", await pollContract.totalPolls());

  try {
    await (
      await pollContract.createPoll("testUrl", "testTitle", "testBio")
    ).wait();
  } catch (error) {
    console.error("expected error", error);
  }

  await (await pollContract.editPoll("testUrl", "testTitle", "testBio")).wait();
  console.log("edited poll", await pollContract.polls(owner.address));
  console.log("pollCount3", await pollContract.totalPolls());

  await (
    await pollContract.connect(randomPerson).propose(owner.address, "proposal1")
  ).wait();
  console.log("proposed", (await pollContract.polls(owner.address)).proposals);
  console.log("pollCount4", await pollContract.totalPolls());

  await (
    await pollContract.overwriteWithNewPoll(
      "testUrl2",
      "testTitle2",
      "testBio2"
    )
  ).wait();
  console.log("overwrote poll", await pollContract.polls(owner.address));
  console.log("pollCount4", await pollContract.totalPolls());
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
