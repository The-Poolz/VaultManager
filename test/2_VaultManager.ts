import { expect } from 'chai';
import { BigNumber, Signer } from 'ethers';
import { ethers } from 'hardhat';
import { VaultManager } from '../typechain-types/contracts/VaultManager';
import { MockTrustee } from '../typechain-types/contracts/test';
import { ERC20Token } from '../typechain-types/poolz-helper-v2/contracts/token';

describe('VaultManager', function () {
  let vaultManager: VaultManager;
  let token: ERC20Token;
  let trustee: MockTrustee
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

    const Trustee = await ethers.getContractFactory('MockTrustee');
    trustee = await Trustee.deploy(vaultManager.address);
    await trustee.deployed();

  });

  it('should set address as trustee', async function () {
    const Trustee = await ethers.getContractFactory('MockTrustee');
    const trustee = await Trustee.deploy(vaultManager.address);
    await trustee.deployed();

    await vaultManager.setTrustee(trustee.address);

    const result = await vaultManager.trustee();
    expect(result).to.equal(trustee.address);
  });

  it("should update the trustee", async () => {
    await vaultManager.setTrustee(trustee.address);
    const newTrustee = await ethers.getContractFactory('MockTrustee');
    const newTrusteeInstance = await newTrustee.deploy(vaultManager.address);
    await newTrusteeInstance.deployed();

    await vaultManager.updateTrustee(newTrusteeInstance.address);

    const result = await vaultManager.trustee();
    expect(result).to.equal(newTrusteeInstance.address);
    expect(result).to.not.equal(trustee.address);
  })

  it('should create a new vault', async function () {
    const vaultId = await vaultManager.callStatic['createNewVault(address)'](token.address);
    await vaultManager['createNewVault(address)'](token.address);

    const totalVaults = await vaultManager.totalVaults();
    expect(totalVaults).to.equal(1);
    expect(vaultId).to.equal(totalVaults.sub(1).toString());

    const vaultAddress = await vaultManager.vaultIdToVault(vaultId);
    expect(vaultAddress).to.not.equal(ethers.constants.AddressZero);

    const isDepositActive = await vaultManager.isDepositActiveForVaultId(vaultId);
    const isWithdrawActive = await vaultManager.isWithdrawalActiveForVaultId(vaultId);
    const [receiverAddress, royaltyAmount] = await vaultManager.royaltyInfo(vaultId,"100");
    expect(isDepositActive).to.equal(true);
    expect(isWithdrawActive).to.equal(true);
    expect(receiverAddress).to.equal(ethers.constants.AddressZero);
    expect(royaltyAmount).to.equal(0);
  });

  it('should get the token address', async function () {
    const vaultId = await vaultManager.callStatic['createNewVault(address)'](token.address);
    await vaultManager['createNewVault(address)'](token.address);

    const tokenAddress = await vaultManager.vaultIdToTokenAddress(vaultId);

    expect(tokenAddress).to.equal(token.address);
  });

  it('should deposit tokens to a vault', async function () {
    await vaultManager.setTrustee(trustee.address);
    const amount = ethers.utils.parseEther('0.000001');
    await token.approve(vaultManager.address, amount);

    const vaultId = await vaultManager.callStatic['createNewVault(address)'](token.address);
    await vaultManager['createNewVault(address)'](token.address);

    await trustee.deposit(token.address, owner.getAddress(), amount);

    const vaultBalance = await vaultManager.getVaultBalanceByVaultId(vaultId);
    const vaultBalanceByToken = await vaultManager.getCurrentVaultBalanceByToken(token.address);
    expect(vaultBalance).to.equal(amount);
    expect(vaultBalanceByToken).to.equal(amount);
  });

  it('should withdraw tokens from a vault', async function () {
    await vaultManager.setTrustee(trustee.address);
    const amount = ethers.utils.parseEther('0.000001');
    await token.approve(vaultManager.address, amount);

    await vaultManager['createNewVault(address)'](token.address);

    const signers = await ethers.getSigners()
    const to = signers[1].address;
    const vaultId = 0; 
    await trustee.deposit(token.address, owner.getAddress(), amount);

    await trustee.withdraw(vaultId, to, amount)

    const vaultBalance = await vaultManager.getVaultBalanceByVaultId(vaultId);
    const vaultBalanceByToken = await vaultManager.getCurrentVaultBalanceByToken(token.address);
    expect(vaultBalance).to.equal(0);
    expect(vaultBalanceByToken).to.equal(0);

    const receiverBalance = await token.balanceOf(to);
    expect(receiverBalance).to.equal(amount);
  });

  it('should support multiple vaults per token', async () => {
    await vaultManager.setTrustee(trustee.address);
    const permitted = allSigners[1];
    const ownerBalance = await token.balanceOf(await owner.getAddress());
    await token.transfer(permitted.getAddress(), ownerBalance);
    await token.connect(permitted).approve(vaultManager.address, ethers.constants.MaxUint256);

    const amounts: BigNumber[] = [];

    for(let i = 0; i < 10; i++) {
      await vaultManager.connect(owner)['createNewVault(address)'](token.address);

      const amount = (Math.floor(Math.random() * 100000) + 1000);
      amounts.push(ethers.BigNumber.from(amount));

      const vaultId = await trustee.connect(permitted).callStatic.deposit(token.address, permitted.getAddress(), amount);
      await trustee.connect(permitted).deposit(token.address, permitted.getAddress(), amount);
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

  it("should create a vault with royalty", async () => {
    const feeNumerator = 100; // 1%
    const vaultId = await vaultManager.callStatic['createNewVault(address,address,uint96)'](token.address, owner.getAddress(), feeNumerator);
    const tx = await vaultManager['createNewVault(address,address,uint96)'](token.address, owner.getAddress(), feeNumerator);

    const totalVaults = await vaultManager.totalVaults();
    expect(totalVaults).to.equal(1);
    expect(vaultId).to.equal(totalVaults.sub(1).toString());

    const vaultAddress = await vaultManager.vaultIdToVault(vaultId);
    expect(vaultAddress).to.not.equal(ethers.constants.AddressZero);

    const isDepositActive = await vaultManager.isDepositActiveForVaultId(vaultId);
    const isWithdrawActive = await vaultManager.isWithdrawalActiveForVaultId(vaultId);
    const [receiverAddress, royaltyAmount] = await vaultManager.royaltyInfo(vaultId,"100");
    expect(isDepositActive).to.equal(true);
    expect(isWithdrawActive).to.equal(true);
    expect(receiverAddress).to.equal(await owner.getAddress());
    expect(royaltyAmount).to.equal(1);
    expect(tx).to.emit(vaultManager, "VaultRoyaltySet").withArgs(vaultId, token.address, await owner.getAddress(), feeNumerator);
  })

  
});