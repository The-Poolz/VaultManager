import { expect } from 'chai';
import { Signer } from 'ethers';
import { ethers } from 'hardhat';
import { VaultManager } from '../typechain-types/contracts/VaultManager';
import { ERC20Token } from '../typechain-types/poolz-helper-v2/contracts/token';

describe('Vault Manager Fail', function () {

  describe("OnlyGovernor Functions", function() {
    let vaultManager: VaultManager;
    let token: ERC20Token;
    let nonGovernor: Signer;

    beforeEach(async function () {
        const Token = await ethers.getContractFactory('ERC20Token');
        token = await Token.deploy("Token", "TKN");
        await token.deployed();
        
        const signers = await ethers.getSigners();
        nonGovernor = signers[1];

        const VaultManager = await ethers.getContractFactory('VaultManager');
        vaultManager = await VaultManager.deploy();
        await vaultManager.deployed();
    });

    it("should fail to create new vault if called by non-governor", async () => {{
        await expect(vaultManager.connect(nonGovernor).createNewVault(token.address))
            .to.be.revertedWith("Authorization Error");
    }})

    it("should fail to setPermitted if called by non-governor", async () => {
        const permittedAddress = await nonGovernor.getAddress();
        await expect(vaultManager.connect(nonGovernor).setPermitted(permittedAddress, true))
            .to.be.revertedWith("Authorization Error");
    })

    it("should fail to set active status if called by non owner", async () => {
        const vaultId = await vaultManager.callStatic.createNewVault(token.address);
        await vaultManager.createNewVault(token.address);

        await expect(vaultManager.connect(nonGovernor).setActiveStatusForVaultId(vaultId, true, true))
            .to.be.revertedWith("Authorization Error");
    })

  });

  describe("Vault does not Exists", function() {
    let vaultManager: VaultManager;
    let token: ERC20Token;
    let governor: Signer;
    const fakeVaultId = "9";


    beforeEach(async function () {
        const Token = await ethers.getContractFactory('ERC20Token');
        token = await Token.deploy("Token", "TKN");
        await token.deployed();
        
        const signers = await ethers.getSigners();
        governor = signers[0];

        const VaultManager = await ethers.getContractFactory('VaultManager');
        vaultManager = await VaultManager.deploy();
        await vaultManager.deployed();

        await vaultManager.setPermitted(governor.getAddress(), true);
    });

    it("should fail to set deposit active status", async () => {
        await expect(vaultManager.setActiveStatusForVaultId(fakeVaultId, true, true))
            .to.be.revertedWith("VaultManager: Vault not found");
    })

    it("should fail to deposit", async () => {
        await expect(vaultManager.depositByToken(token.address, governor.getAddress(), 100))
            .to.be.revertedWith("VaultManager: Vault not found");
    })

    it("should fail to withdraw", async () => {
        await expect(vaultManager.withdrawByVaultId(fakeVaultId, governor.getAddress(), 100))
            .to.be.revertedWith("VaultManager: Vault not found");
    })

    it("should fail to return balance", async () => {
        await expect(vaultManager.getVaultBalanceByVaultId(fakeVaultId))
            .to.be.revertedWith("VaultManager: Vault not found");
    })
    it("should fail to return balance", async () => {
        await expect(vaultManager.getVaultBalanceByVaultId(fakeVaultId))
            .to.be.revertedWith("VaultManager: Vault not found");
        await expect(vaultManager.getVaultBalanceByToken(token.address))
            .to.be.revertedWith("VaultManager: Vault not found");
    })

    it("should return zero for mappings", async () => {
        expect(await vaultManager.vaultIdToVault(fakeVaultId)).to.equal(ethers.constants.AddressZero);
        expect(await vaultManager.isDepositActiveForVaultId(fakeVaultId)).to.equal(false);
        expect(await vaultManager.isWithdrawalActiveForVaultId(fakeVaultId)).to.equal(false);
    })
  })

  describe("Permitted Functions", function () {
    let vaultManager: VaultManager;
    let token: ERC20Token;
    let governor: Signer;
    let nonPermitted: Signer;
    let vaultId: string

    beforeEach(async function () {
        const Token = await ethers.getContractFactory('ERC20Token');
        token = await Token.deploy("Token", "TKN");
        await token.deployed();
        
        const signers = await ethers.getSigners();
        governor = signers[0];
        nonPermitted = signers[1];

        const VaultManager = await ethers.getContractFactory('VaultManager');
        vaultManager = await VaultManager.deploy();
        await vaultManager.deployed();

        await vaultManager.setPermitted(governor.getAddress(), true);
        vaultId = (await vaultManager.callStatic.createNewVault(token.address)).toString();
        await vaultManager.createNewVault(token.address);
    });

    it("should fail to deposit", async () => {
      await expect(vaultManager.connect(nonPermitted).depositByToken(token.address, nonPermitted.getAddress(), 100))
          .to.be.revertedWith("VaultManager: Not permitted");
    });
    it("should fail to withdraw", async () => {
      await expect(vaultManager.connect(nonPermitted).withdrawByVaultId(vaultId, nonPermitted.getAddress(), 100))
          .to.be.revertedWith("VaultManager: Not permitted");
    });

  });

  describe("Deposite and Withdrawal Status", function() {
    let vaultManager: VaultManager;
    let token: ERC20Token;
    let governor: Signer;
    let vaultId: string

    beforeEach(async function () {
        const Token = await ethers.getContractFactory('ERC20Token');
        token = await Token.deploy("Token", "TKN");
        await token.deployed();
        
        const signers = await ethers.getSigners();
        governor = signers[0];

        const VaultManager = await ethers.getContractFactory('VaultManager');
        vaultManager = await VaultManager.deploy();
        await vaultManager.deployed();

        await vaultManager.setPermitted(governor.getAddress(), true);
        vaultId = (await vaultManager.callStatic.createNewVault(token.address)).toString();
        await vaultManager.createNewVault(token.address);
        await vaultManager.setActiveStatusForVaultId(vaultId, false, false);
    });

    it("should fail to deposit", async () => {
      await expect(vaultManager.depositByToken(token.address, governor.getAddress(), 100))
         .to.be.revertedWith("VaultManager: Deposits are frozen");
    });

    it("should fail to withdraw", async () => {
      await expect(vaultManager.withdrawByVaultId(vaultId, governor.getAddress(), 100))
         .to.be.revertedWith("VaultManager: Withdrawals are frozen");
    });

  })

  
});