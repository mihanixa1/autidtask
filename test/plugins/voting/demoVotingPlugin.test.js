const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

let demoVotingPlugin;
let deployer;
let admin, submitter1, submitter2, addr1, addr2, addr3, addrs;
const url = "https://something";
let pluginTypeId;
let autID;
let block;


describe("DemoVotingPlugin", (accounts) => {
  before(async function () {
    [
      admin,
      verifier,
      dao,
      member1,
      member2,
      addr1,
      addr2,
      addr3,
      ...addrs
    ] = await ethers.getSigners();

    const ModuleRegistryFactory = await ethers.getContractFactory("ModuleRegistry");
    const moduleRegistry = await ModuleRegistryFactory.deploy();

    const PluginRegistryFactory = await ethers.getContractFactory(
      "PluginRegistry"
    );
    pluginRegistry = await PluginRegistryFactory.deploy(moduleRegistry.address);
    const AutID = await ethers.getContractFactory("AutID");

    autID = await upgrades.deployProxy(AutID, [admin.address], {
      from: admin,
    });
    await autID.deployed();
    const Nova = await ethers.getContractFactory("Nova");
    dao = await Nova.deploy(
      admin.address,
      autID.address,
      1,
      url,
      10,
      pluginRegistry.address
    );

    const pluginDefinition = await (
      await pluginRegistry.addPluginDefinition(verifier.address, url, 0, true, [])
    ).wait();
    pluginTypeId = pluginDefinition.events[0].args.pluginTypeId.toString();

    await (
      await autID
        .connect(member1)
        .mint("username1", url, 2, 5, dao.address)
    ).wait();
  
    // await (
    //   await autID.connect(member1).joinDAO(2, 5, dao.address)
    // ).wait();

    const blockNumber = await ethers.provider.getBlockNumber();
    block = await ethers.provider.getBlock(blockNumber);

    console.log(block.timestamp);

  });

  describe("Plugin Registration", async () => {
    it("Should deploy a DemoVotingPlugin", async () => {
      const DemoVotingPlugin = await ethers.getContractFactory(
        "DemoVotingPlugin"
      );
      demoVotingPlugin = await DemoVotingPlugin.deploy(
        dao.address
      );

      expect(demoVotingPlugin.address).not.null;
    });
    it("Should mint an NFT for it", async () => {
      const tx = await pluginRegistry
        .connect(admin)
        .addPluginToDAO(demoVotingPlugin.address, pluginTypeId);
      await expect(tx)
        .to.emit(pluginRegistry, "PluginAddedToDAO")
        .withArgs(1, pluginTypeId, dao.address);
    });
  });

  describe("#createProposal", async () => {
    describe("when member submits a valid proposal", async () => {
      it("emits ProposalCreated event", async () => {
        const tx = demoVotingPlugin.connect(member1).createProposal(
          block.timestamp + 100,
          block.timestamp + 101,
          ethers.utils.toUtf8Bytes(url)
        );
        await expect(tx).to.emit(demoVotingPlugin, "ProposalCreated");
      });
    });
    describe("when stranger submits a proposal", async() => {
      it("reverts with not a member", async () => {
        const tx = demoVotingPlugin.connect(addr1).createProposal(
          block.timestamp + 100,
          block.timestamp + 101,
          ethers.utils.toUtf8Bytes(url)
        );
        await expect(tx).to.revertedWith("not a member");
      });
    });
    // todo: check threshold
    // todo: check cooldown
    // note: pls hire for full test coverage
  });

  describe("#vote", async () => {
    describe("when member votes", () => {
      it("emits Voted event and reflects votingScore", async () => {
        await ethers.provider.send("evm_increaseTime", [3600]);
        await ethers.provider.send("evm_mine");
        const tx = demoVotingPlugin.connect(member1).createProposal(
          block.timestamp + 3600 + 100,
          block.timestamp + 3600 + 1000,
          ethers.utils.toUtf8Bytes(url)
        );
        await expect(tx).to.emit(demoVotingPlugin, "ProposalCreated");
        await ethers.provider.send("evm_increaseTime", [100]);
        await ethers.provider.send("evm_mine");
        const tx2 = demoVotingPlugin.connect(member1).vote(1, true);
        await expect(tx2).to.emit(demoVotingPlugin, "Voted");
        
        expect((await demoVotingPlugin.getVotingScore(1)).toString()).to.eql("21");
      });
    });
  });
});
