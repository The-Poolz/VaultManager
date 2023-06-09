import { expect, assert } from 'chai';
import { Signer } from 'ethers';
import { ethers } from 'hardhat';
import { VaultManager } from '../typechain-types/contracts/VaultManager';
import { ERC20Token } from '../typechain-types/poolz-helper-v2/contracts/token';

describe('VaultManager', function () {
  let vaultManager: VaultManager;
  let token: ERC20Token;
  let owner: Signer;

  beforeEach(async function () {
    const Token = await ethers.getContractFactory('ERC20Token');
    token = await Token.deploy("Token", "TKN");
    await token.deployed();
    
    const signers = await ethers.getSigners();
    owner = signers[0]; 
    // console.log(signers.length)
    // console.log(owner.getAddress())

    const VaultManager = await ethers.getContractFactory('VaultManager');
    vaultManager = await VaultManager.deploy();
    await vaultManager.deployed();
    const tx = VaultManager.getDeployTransaction()
    // console.log(tx)


    await vaultManager.setPermitted(owner.getAddress(), true);
  });

  it('should set address as permitted', async function () {
    const signers = await ethers.getSigners();
    const permittedAddress = signers[1].address; 

    await vaultManager.setPermitted(permittedAddress, true);

    const isPermitted = await vaultManager.isPermitted(permittedAddress);
    expect(isPermitted).to.equal(true);
  });

  it('should unset address as permitted', async function () {
    const signers = await ethers.getSigners();
    const permittedAddress = signers[1].address; 

    await vaultManager.setPermitted(permittedAddress, true);
    await vaultManager.setPermitted(permittedAddress, false);

    const isPermitted = await vaultManager.isPermitted(permittedAddress);
    expect(isPermitted).to.equal(false);
  });

  it('should create a new vault', async function () {
    await vaultManager.CreateNewVault(token.address);

    const totalVaults = await vaultManager.TotalVaults();
    expect(totalVaults).to.equal(1);

    const vaultAddress = await vaultManager.VaultIdToVault(totalVaults.sub(1));
    expect(vaultAddress).to.not.equal(ethers.constants.AddressZero);
  });

  it('should deposit tokens to a vault', async function () {
    const amount = ethers.utils.parseEther('0.000001');
    await token.approve(vaultManager.address, amount);

    await vaultManager.CreateNewVault(token.address);

    const from = await owner.getAddress();
    const vaultId = 0; 

    await vaultManager.DepositByToken(token.address, from, amount);

    const vaultBalance = await vaultManager.getVaultBalanceByVaultId(vaultId);
    expect(vaultBalance).to.equal(amount);
  });

  it('should withdraw tokens from a vault', async function () {
    const amount = ethers.utils.parseEther('0.000001');
    await token.approve(vaultManager.address, amount);

    await vaultManager.CreateNewVault(token.address);

    const from = await owner.getAddress();
    const signers = await ethers.getSigners()
    const to = signers[1].address;
    const vaultId = 0; 
    await vaultManager.DepositByToken(token.address, from, amount);

    await vaultManager.WithdrawByVaultId(vaultId, to, amount);

    const vaultBalance = await vaultManager.getVaultBalanceByVaultId(vaultId);
    expect(vaultBalance).to.equal(0);

    const receiverBalance = await token.balanceOf(to);
    expect(receiverBalance).to.equal(amount);
  });

  it('should delete a vault when it is empty', async () => {
    
    await vaultManager.CreateNewVault(ethers.constants.AddressZero);
    await vaultManager.CreateNewVault(token.address);
    const vaultId = 1
    const tx = await vaultManager.DeleteVault(token.address)
    const receipt = await tx.wait()
    if(receipt.events == undefined || receipt.events[0].args == undefined){
      assert.fail("receipt events is undefined")
    }
    expect(receipt.events[0].event).to.equal('VaultDeleted')
    expect(receipt.events[0].args[0]).to.equal(vaultId)
    expect(receipt.events[0].args[1]).to.equal(token.address)

    // Verify that the vault has been deleted
    expect(await vaultManager.VaultIdToVault(vaultId)).to.equal(ethers.constants.AddressZero);
    expect(await vaultManager.TokenToVaultId(token.address)).to.equal(0);
  });

  it('should revert when trying to delete a non-empty vault', async () => {
    await vaultManager.CreateNewVault(token.address);
    const vaultId = 0;
    const Vault = await ethers.getContractFactory('Vault');
    const vault = await Vault.attach(await vaultManager.VaultIdToVault(vaultId));
    const amount = ethers.utils.parseEther('0.000001');
    await token.approve(vaultManager.address, amount);

    // Deposit some tokens into the vault
    await vaultManager.DepositByToken(token.address, owner.getAddress(), 100);
    expect(await vaultManager.getVaultBalanceByVaultId(vaultId)).to.equal(100);

    // Attempt to delete the non-empty vault
    await expect(vaultManager.DeleteVault(token.address)).to.be.revertedWith('VaultManager: Vault not empty');

    // Verify that the vault still exists
    expect(await vaultManager.VaultIdToVault(vaultId)).to.equal(vault.address);
    expect(await vaultManager.TokenToVaultId(token.address)).to.equal(vaultId);
  });
});