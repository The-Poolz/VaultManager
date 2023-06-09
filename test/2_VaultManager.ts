import { expect } from 'chai';
import { BigNumber, Signer } from 'ethers';
import { ethers } from 'hardhat';
import { VaultManager } from '../typechain-types/contracts/VaultManager';
import { ERC20Token } from '../typechain-types/poolz-helper-v2/contracts/token';

describe('VaultManager', function () {
  let vaultManager: VaultManager;
  let token: ERC20Token;
  let owner: Signer;
  let allSigners: Signer[];

  beforeEach(async function () {
    const Token = await ethers.getContractFactory('ERC20Token');
    token = await Token.deploy("Token", "TKN");
    await token.deployed();
    
    allSigners = await ethers.getSigners();
    owner = allSigners[0]; 

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

  it('should get the token address', async function () {
    const vaultId = await vaultManager.callStatic.createNewVault(token.address);
    await vaultManager.createNewVault(token.address);

    const tokenAddress = await vaultManager.vaultIdToTokenAddress(vaultId);

    expect(tokenAddress).to.equal(token.address);
  });

  it('should deposit tokens to a vault', async function () {
    const amount = ethers.utils.parseEther('0.000001');
    await token.approve(vaultManager.address, amount);

    const vaultId = await vaultManager.callStatic.createNewVault(token.address);
    await vaultManager.createNewVault(token.address);

    const from = await owner.getAddress();

    await vaultManager.depositByToken(token.address, from, amount);

    const vaultBalance = await vaultManager.getVaultBalanceByVaultId(vaultId);
    const vaultBalanceByToken = await vaultManager.getCurrentVaultBalanceByToken(token.address);
    expect(vaultBalance).to.equal(amount);
    expect(vaultBalanceByToken).to.equal(amount);
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
    const vaultBalanceByToken = await vaultManager.getCurrentVaultBalanceByToken(token.address);
    expect(vaultBalance).to.equal(0);
    expect(vaultBalanceByToken).to.equal(0);

    const receiverBalance = await token.balanceOf(to);
    expect(receiverBalance).to.equal(amount);
  });

  it('should support multiple vaults per token', async () => {
    const permitted = allSigners[1];
    const ownerBalance = await token.balanceOf(await owner.getAddress());
    await token.transfer(permitted.getAddress(), ownerBalance);
    await token.connect(permitted).approve(vaultManager.address, ethers.constants.MaxUint256);
    await vaultManager.setPermitted(permitted.getAddress());
    const amounts: BigNumber[] = [];

    for(let i = 0; i < 10; i++) {
      await vaultManager.connect(owner).createNewVault(token.address);

      const amount = (Math.floor(Math.random() * 100000) + 1000);
      amounts.push(ethers.BigNumber.from(amount));
      const vaultId = await vaultManager.connect(permitted).callStatic.depositByToken(token.address, await permitted.getAddress(), amount);
      await vaultManager.connect(permitted).depositByToken(token.address, await permitted.getAddress(), amount);
      const vaultBalance = await vaultManager.getVaultBalanceByVaultId(vaultId);
      const vaultBalanceByToken = await vaultManager.getCurrentVaultBalanceByToken(token.address);
      const totalBalance = await vaultManager.getAllVaultBalanceByToken(token.address);
      const totalVaults = await vaultManager.totalVaults();
      const totalNumberOfTokens = await vaultManager.getTotalNumberOfTokens();
      const vaultToken = await vaultManager.allTokens(0);
      const allTokens = await vaultManager.getAllTokens();
      expect(totalVaults).to.equal(i + 1);
      expect(vaultBalance).to.equal(amount);
      expect(vaultBalanceByToken).to.equal(amount);
      expect(totalNumberOfTokens).to.equal(1);
      expect(totalBalance).to.equal(amounts.reduce((a, b) => a.add(b), ethers.constants.Zero));
      expect(vaultToken).to.equal(token.address);
      expect(allTokens).to.deep.equal([token.address]);
    }

  })

  
});