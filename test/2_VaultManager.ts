import { expect } from 'chai';
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

    const VaultManager = await ethers.getContractFactory('VaultManager');
    vaultManager = await VaultManager.deploy();
    await vaultManager.deployed();

    await vaultManager.setPermitted(owner.getAddress());
  });

  it('should set address as permitted', async function () {
    const signers = await ethers.getSigners();
    const permittedAddress = signers[1].address; 

    await vaultManager.setPermitted(permittedAddress);

    const isPermitted = await vaultManager.permittedAddress();
    expect(isPermitted).to.equal(permittedAddress);
  });

  it('should unset address as permitted', async function () {
    const signers = await ethers.getSigners();
    const permittedAddress = signers[1].address; 

    await vaultManager.setPermitted(permittedAddress);

    const isPermitted = await vaultManager.permittedAddress();
    expect(isPermitted).to.equal(permittedAddress);
  });

  it('should create a new vault', async function () {
    const vaultId = await vaultManager.callStatic.createNewVault(token.address);
    await vaultManager.createNewVault(token.address);

    const totalVaults = await vaultManager.totalVaults();
    expect(totalVaults).to.equal(1);
    expect(vaultId).to.equal(totalVaults.sub(1).toString());

    const vaultAddress = await vaultManager.vaultIdToVault(vaultId);
    expect(vaultAddress).to.not.equal(ethers.constants.AddressZero);

    const isDepositActive = await vaultManager.isDepositActiveForVaultId(vaultId);
    const isWithdrawActive = await vaultManager.isWithdrawalActiveForVaultId(vaultId);
    expect(isDepositActive).to.equal(true);
    expect(isWithdrawActive).to.equal(true);
  });

  it('should deposit tokens to a vault', async function () {
    const amount = ethers.utils.parseEther('0.000001');
    await token.approve(vaultManager.address, amount);

    const vaultId = await vaultManager.callStatic.createNewVault(token.address);
    await vaultManager.createNewVault(token.address);

    const from = await owner.getAddress();

    await vaultManager.depositByToken(token.address, from, amount);

    const vaultBalance = await vaultManager.getVaultBalanceByVaultId(vaultId);
    expect(vaultBalance).to.equal(amount);
  });

  it('should withdraw tokens from a vault', async function () {
    const amount = ethers.utils.parseEther('0.000001');
    await token.approve(vaultManager.address, amount);

    await vaultManager.createNewVault(token.address);

    const from = await owner.getAddress();
    const signers = await ethers.getSigners()
    const to = signers[1].address;
    const vaultId = 0; 
    await vaultManager.depositByToken(token.address, from, amount);

    await vaultManager.withdrawByVaultId(vaultId, to, amount);

    const vaultBalance = await vaultManager.getVaultBalanceByVaultId(vaultId);
    expect(vaultBalance).to.equal(0);

    const receiverBalance = await token.balanceOf(to);
    expect(receiverBalance).to.equal(amount);
  });

  
});