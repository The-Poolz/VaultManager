import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Vault } from '../typechain-types/contracts/Vault';
import { ERC20Token } from '../typechain-types/poolz-helper-v2/contracts/token';

describe('Vault', function () {
  let vault: Vault;
  let token: ERC20Token;
  let signers: SignerWithAddress[]

  beforeEach(async function () {
    const Token = await ethers.getContractFactory('ERC20Token');
    token = await Token.deploy("Token", "TKN");
    await token.deployed();

    const Vault = await ethers.getContractFactory('Vault');
    vault = (await Vault.deploy(token.address)) as Vault;
    await vault.deployed();

    signers= await ethers.getSigners();
  });

  it('should have the correct token address', async function () {
    expect(await vault.tokenAddress()).to.equal(token.address);
  });

  it('should have the correct vault manager', async function () {
    expect(await vault.vaultManager()).to.equal(signers[0].address);
  });

  it('should return the correct token balance', async function () {
    const balance = await token.balanceOf(vault.address);
    expect(await vault.tokenBalance()).to.equal(balance);
  });

  it('should allow the manager to withdraw tokens', async function () {
    const amount = ethers.utils.parseEther('0.0000001');
    await token.transfer(vault.address, amount);

    const receiver = signers[1].address;
    await vault.withdraw(receiver, amount);

    expect(await token.balanceOf(receiver)).to.equal(amount);
  });

});