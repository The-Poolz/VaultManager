import { MockTrustee } from "../typechain-types";
import { VaultManager } from "../typechain-types/contracts/VaultManager";
import { ERC20Token } from "../typechain-types/poolz-helper-v2/contracts/token";
import { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { getDepositeHashToSign } from "./utils";

describe("Vault Manager Fail", function () {
  describe("OnlyGovernor Functions", function () {
    let vaultManager: VaultManager;
    let token: ERC20Token;
    let nonGovernor: Signer;
    let governor: Signer;
    let trustee: MockTrustee;

    beforeEach(async function () {
      const Token = await ethers.getContractFactory("ERC20Token");
      token = await Token.deploy("Token", "TKN");
      await token.deployed();

      const signers = await ethers.getSigners();
      governor = signers[0];
      nonGovernor = signers[1];

      const VaultManager = await ethers.getContractFactory("VaultManager");
      vaultManager = await VaultManager.deploy();
      await vaultManager.deployed();

      const Trustee = await ethers.getContractFactory("MockTrustee");
      trustee = await Trustee.deploy(vaultManager.address);
      await trustee.deployed();
    });

    it("should fail to create new vault if called by non-governor(without royalty and tradeStartTime)", async () => {
      {
        await expect(
          vaultManager
            .connect(nonGovernor)
            ["createNewVault(address)"](token.address)
        ).to.be.revertedWith("Ownable: caller is not the owner");
      }
    });

    it("should fail to create new vault if called by non-governor(with royalty)", async () => {
      {
        await expect(
          vaultManager
            .connect(nonGovernor)
            ["createNewVault(address,address,uint96)"](
              token.address,
              nonGovernor.getAddress(),
              100
            )
        ).to.be.revertedWith("Ownable: caller is not the owner");
      }
    });

    it("should fail to create new vault if called by non-governor(with tradeStartTime)", async () => {
      await expect(
        vaultManager
          .connect(nonGovernor)
          ["createNewVault(address,uint256)"](token.address, 100)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail to create new vault if called by non-governor(with royalty and tradeStartTime)", async () => {
      await expect(
        vaultManager
          .connect(nonGovernor)
          ["createNewVault(address,uint256,address,uint96)"](
            token.address,
            100,
            nonGovernor.getAddress(),
            100
          )
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail to create new vault with token as zero address", async () => {
      await expect(
        vaultManager["createNewVault(address)"](ethers.constants.AddressZero)
      ).to.be.revertedWith("VaultManager: Zero address not allowed");
    });

    it("should fail to create new vault with royalty receiver as zero address", async () => {
      await expect(
        vaultManager["createNewVault(address,address,uint96)"](
          token.address,
          ethers.constants.AddressZero,
          100
        )
      ).to.be.revertedWith("VaultManager: Zero address not allowed");
    });

    it("should fail to create new vault with incorrect feeNumerator", async () => {
      await expect(
        vaultManager
          .connect(governor)
          ["createNewVault(address,address,uint96)"](
            token.address,
            governor.getAddress(),
            10001
          )
      ).to.be.revertedWith("VaultManager: Royalty cannot be more than 100%");
    });

    it("should fail to setTrustee if called by non-governor", async () => {
      const permittedAddress = await nonGovernor.getAddress();
      await expect(
        vaultManager.connect(nonGovernor).setTrustee(permittedAddress)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail to setTrustee if called by non-governor", async () => {
      const permittedAddress = await nonGovernor.getAddress();
      await expect(
        vaultManager.connect(nonGovernor).updateTrustee(permittedAddress)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail to set EOA as trustee", async () => {
      await expect(
        vaultManager.setTrustee(nonGovernor.getAddress())
      ).to.be.revertedWith("VaultManager: EOA not allowed");
    });

    it("should fail to update trustee to EOA", async () => {
      await expect(
        vaultManager.updateTrustee(nonGovernor.getAddress())
      ).to.be.revertedWith("VaultManager: EOA not allowed");
    });

    it("should fail to set Zero address as trustee", async () => {
      await expect(
        vaultManager.setTrustee(ethers.constants.AddressZero)
      ).to.be.revertedWith("VaultManager: Zero address not allowed");
    });

    it("should fail to update trustee to Zero address", async () => {
      await expect(
        vaultManager.updateTrustee(ethers.constants.AddressZero)
      ).to.be.revertedWith("VaultManager: Zero address not allowed");
    });

    it("should fail to update trustee initially", async () => {
      await expect(
        vaultManager.updateTrustee(trustee.address)
      ).to.be.revertedWith("VaultManager: Trustee not set yet");
    });

    it("should fail to set trustee after it is already set", async () => {
      await vaultManager.setTrustee(trustee.address);
      await expect(vaultManager.setTrustee(trustee.address)).to.be.revertedWith(
        "VaultManager: Trustee already set"
      );
    });

    it("should fail to set active status if called by non owner", async () => {
      const vaultId = await vaultManager.callStatic["createNewVault(address)"](
        token.address
      );
      await vaultManager["createNewVault(address)"](token.address);

      await expect(
        vaultManager
          .connect(nonGovernor)
          .setActiveStatusForVaultId(vaultId, true, true)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail to start tradeStartTime if called by non owner", async () => {
      const vaultId = await vaultManager.callStatic["createNewVault(address)"](
        token.address
      );
      await vaultManager["createNewVault(address)"](token.address);

      await expect(
        vaultManager.connect(nonGovernor).setTradeStartTime(vaultId, 100)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail to set tradeStartTime when vault does not exist", async () => {
      await expect(vaultManager.setTradeStartTime(100, 100)).to.be.revertedWith(
        "VaultManager: Vault not found"
      );
    });
  });

  describe("Vault does not Exists", function () {
    let vaultManager: VaultManager;
    let trustee: MockTrustee;
    let token: ERC20Token;
    let governor: Signer;
    const fakeVaultId = "9";

    beforeEach(async function () {
      const Token = await ethers.getContractFactory("ERC20Token");
      token = await Token.deploy("Token", "TKN");
      await token.deployed();

      const signers = await ethers.getSigners();
      governor = signers[0];

      const VaultManager = await ethers.getContractFactory("VaultManager");
      vaultManager = await VaultManager.deploy();
      await vaultManager.deployed();

      const Trustee = await ethers.getContractFactory("MockTrustee");
      trustee = await Trustee.deploy(vaultManager.address);
      await trustee.deployed();

      await vaultManager.setTrustee(trustee.address);
    });

    it("should fail to set deposit active status", async () => {
      await expect(
        vaultManager.setActiveStatusForVaultId(fakeVaultId, true, true)
      ).to.be.revertedWith("VaultManager: Vault not found");
    });

    it("should fail to deposit", async () => {
      const amount = 100;
      await token.approve(trustee.address, amount);
      await expect(trustee.deposit(token.address, amount)).to.be.revertedWith(
        "VaultManager: No vaults for this token"
      );
    });

    it("should fail to withdraw", async () => {
      await expect(
        trustee.withdraw(fakeVaultId, governor.getAddress(), 100)
      ).to.be.revertedWith("VaultManager: Vault not found");
    });

    it("should fail to return balance", async () => {
      await expect(
        vaultManager.getVaultBalanceByVaultId(fakeVaultId)
      ).to.be.revertedWith("VaultManager: Vault not found");
    });
    it("should fail to return balance", async () => {
      await expect(
        vaultManager.getVaultBalanceByVaultId(fakeVaultId)
      ).to.be.revertedWith("VaultManager: Vault not found");
      await expect(
        vaultManager.getCurrentVaultBalanceByToken(token.address)
      ).to.be.revertedWith("VaultManager: No vaults for this token");
    });

    it("should fail to return tokenAddress for vaultId which does not", async () => {
      await expect(
        vaultManager.vaultIdToTokenAddress(fakeVaultId)
      ).to.be.revertedWith("VaultManager: Vault not found");
    });

    it("should return zero for mappings", async () => {
      expect(await vaultManager.vaultIdToVault(fakeVaultId)).to.equal(
        ethers.constants.AddressZero
      );
      expect(
        await vaultManager.isDepositActiveForVaultId(fakeVaultId)
      ).to.equal(false);
      expect(
        await vaultManager.isWithdrawalActiveForVaultId(fakeVaultId)
      ).to.equal(false);
    });
  });

  describe("Trustee Functions", function () {
    let vaultManager: VaultManager;
    let trustee: MockTrustee;
    let token: ERC20Token;
    let nonPermitted: Signer;
    let vaultId: string;
    let depositor: Signer

    beforeEach(async function () {
      const Token = await ethers.getContractFactory("ERC20Token");
      token = await Token.deploy("Token", "TKN");
      await token.deployed();

      const signers = await ethers.getSigners();
      nonPermitted = signers[1];
      depositor = signers[2];

      const VaultManager = await ethers.getContractFactory("VaultManager");
      vaultManager = await VaultManager.deploy();
      await vaultManager.deployed();

      const Trustee = await ethers.getContractFactory("MockTrustee");
      trustee = await Trustee.deploy(vaultManager.address);
      await trustee.deployed();

      await vaultManager.setTrustee(trustee.address);
      vaultId = (
        await vaultManager.callStatic["createNewVault(address)"](token.address)
      ).toString();
      await vaultManager["createNewVault(address)"](token.address);
    });

    it("should fail to deposit when called by non trustee", async () => {
      const amount = 100;
      await token.approve(trustee.address, amount);
      await expect(
        vaultManager.connect(nonPermitted).depositByToken(token.address, amount)
      ).to.be.revertedWith("VaultManager: Not Trustee");
    });

    it("should fail to withdraw when called by non trustee", async () => {
      await expect(
        vaultManager
          .connect(nonPermitted)
          .withdrawByVaultId(vaultId, nonPermitted.getAddress(), 100)
      ).to.be.revertedWith("VaultManager: Not Trustee");
    });

    it("should fail to safe deposit when called by non trustee", async () => {
      const currentNonce = await vaultManager.nonces(depositor.getAddress());
      const hashToSign = getDepositeHashToSign(token.address, 100, currentNonce);
      const signature = await depositor.signMessage(hashToSign);
      await expect(
        vaultManager
          .connect(nonPermitted)
          .safeDeposit(token.address, 100, depositor.getAddress(), signature)
      ).to.be.revertedWith("VaultManager: Not Trustee");
    });

    it("should fail to safe deposit when tx.origin signs wrong fromAddress", async () => {
        const currentNonce = await vaultManager.nonces(depositor.getAddress());
        const hashToSign = getDepositeHashToSign(token.address, 100, currentNonce);
        const signature = await nonPermitted.signMessage(hashToSign);
        const tx = trustee.connect(nonPermitted).safeDeposit(token.address, 100, depositor.getAddress(), signature);
        await expect(tx).to.be.revertedWith("VaultManager: Only origin can deposit");
    });

    it("should fail to safe deposit when incorrect amount is signed", async () => {
        const currentNonce = await vaultManager.nonces(depositor.getAddress());
        const hashToSign = getDepositeHashToSign(token.address, 100, currentNonce);
        const signature = await depositor.signMessage(hashToSign);
        const tx = trustee.connect(depositor).safeDeposit(token.address, 1000, depositor.getAddress(), signature);
        await expect(tx).to.be.revertedWith("VaultManager: Only origin can deposit");
    });
  });

  describe("Deposite and Withdrawal Status", function () {
    let vaultManager: VaultManager;
    let trustee: MockTrustee;
    let token: ERC20Token;
    let governor: Signer;
    let vaultId: string;

    beforeEach(async function () {
      const Token = await ethers.getContractFactory("ERC20Token");
      token = await Token.deploy("Token", "TKN");
      await token.deployed();

      const signers = await ethers.getSigners();
      governor = signers[0];

      const VaultManager = await ethers.getContractFactory("VaultManager");
      vaultManager = await VaultManager.deploy();
      await vaultManager.deployed();

      const Trustee = await ethers.getContractFactory("MockTrustee");
      trustee = await Trustee.deploy(vaultManager.address);
      await trustee.deployed();

      await vaultManager.setTrustee(trustee.address);
      vaultId = (
        await vaultManager.callStatic["createNewVault(address)"](token.address)
      ).toString();
      await vaultManager["createNewVault(address)"](token.address);
      await vaultManager.setActiveStatusForVaultId(vaultId, false, false);
    });

    it("should fail to deposit when deposits are frozen", async () => {
      const amount = 100;
      await token.approve(trustee.address, amount);
      await expect(trustee.deposit(token.address, amount)).to.be.revertedWith(
        "VaultManager: Deposits are frozen"
      );
    });

    it("should fail to withdraw when withdrawals are frozen", async () => {
      await expect(
        trustee.withdraw(vaultId, governor.getAddress(), 100)
      ).to.be.revertedWith("VaultManager: Withdrawals are frozen");
    });

    it("should fail to safe deposit when deposits are frozen", async () => {
      const currentNonce = await vaultManager.nonces(governor.getAddress());
      const hashToSign = getDepositeHashToSign(token.address, 100, currentNonce);
      const signature = await governor.signMessage(hashToSign);
      await expect(
        trustee.safeDeposit(token.address, 100, governor.getAddress(), signature)
      ).to.be.revertedWith("VaultManager: Deposits are frozen");
    });

  });
});
