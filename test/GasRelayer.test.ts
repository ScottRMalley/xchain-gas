import { ethers } from "hardhat";
import { LZ_CHAIN_IDS } from "../constants/endpoints";
import { expect } from "chai";
import { GasRelayerMock, LZEndpointMock } from "../typechain-types";
import { AbiCoder } from "ethers";

// Test constants
const PROTOCOL_FEE_DEFAULT = ethers.parseEther("0.0001");
const LOCAL_CHAIN_ID = LZ_CHAIN_IDS[5];
const REMOTE_CHAIN_ID = LZ_CHAIN_IDS[43113];

describe("GasRelayer", function () {
  const deployFixture = async (): Promise<{ gasRelayer: GasRelayerMock, endpoint: LZEndpointMock }> => {


    // deploy endpoint mocks
    const endpointFactory = await ethers.getContractFactory("LZEndpointMock");
    const localEndpoint = await endpointFactory.deploy(LOCAL_CHAIN_ID);

    // the GasRelayerMock should be exactly the same as the GasRelayer
    // with only function visibility changed
    const gasRelayerFactory = await ethers.getContractFactory("GasRelayerMock");
    const gasRelayer = await gasRelayerFactory.deploy(
      await localEndpoint.getAddress(),
      PROTOCOL_FEE_DEFAULT,
      // TODO: update to real values
      ethers.ZeroAddress,
      ethers.ZeroAddress,
      ethers.ZeroAddress,
      50
    );

    // set trusted remote
    const address = await gasRelayer.getAddress();
    await localEndpoint.setDestLzEndpoint(address, await localEndpoint.getAddress());
    const trustedRemote = ethers.solidityPacked(
      ["address", "address"],
      [address, address]
    );
    await gasRelayer.setTrustedRemote(REMOTE_CHAIN_ID, trustedRemote);

    return {gasRelayer, endpoint: localEndpoint};
  }

  it("should deploy", async function () {
    const {gasRelayer, endpoint} = await deployFixture();
    expect(await gasRelayer.getAddress()).to.not.be.undefined;
    expect(await endpoint.getAddress()).to.not.be.undefined;
  });

  it("should estimate a fee", async function () {
    const {gasRelayer} = await deployFixture();
    const [signer] = await ethers.getSigners();
    const feeEstimate = await gasRelayer.estimateFeeRelay(REMOTE_CHAIN_ID, await signer.getAddress());
    expect(feeEstimate).to.be.gt(PROTOCOL_FEE_DEFAULT);
  });

  it("should emit an event on gas relay", async function () {
    const {gasRelayer} = await deployFixture();
    const [signer] = await ethers.getSigners();
    const feeEstimate = await gasRelayer.estimateFeeRelay(REMOTE_CHAIN_ID, await signer.getAddress());
    await expect(gasRelayer.relay(REMOTE_CHAIN_ID, {value: feeEstimate}))
      .to.emit(gasRelayer, "GasSent");
  });

  it("should emit an event when receiving gas", async function () {
    const {gasRelayer} = await deployFixture();
    const [signer] = await ethers.getSigners();

    await expect(gasRelayer.nonblockingLzReceiveMock(
      REMOTE_CHAIN_ID,
      ethers.ZeroAddress,
      0n,
      AbiCoder.defaultAbiCoder().encode(["address"], [await signer.getAddress()])
    ))
      .to.emit(gasRelayer, "GasReceived")
      .withArgs(await signer.getAddress(), REMOTE_CHAIN_ID);
  });
});
