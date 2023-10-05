import { BigNumber } from "ethers";
import { ethers } from "hardhat";

export const getDepositeHashToSign = (tokenAddress: string, fromAddress: string, amount: BigNumber | number, nonce: BigNumber) => {
    const types = ['address', 'address', 'uint256', 'uint256'];
    const values = [tokenAddress, fromAddress, amount.toString(), nonce.toString()];
    const packedData = ethers.utils.solidityPack(types, values);
    const keccekData = ethers.utils.keccak256(packedData);
    const arraryedData = ethers.utils.arrayify(keccekData);
    return arraryedData;
}

export const mockSign = "0x03c9b85bcd278bbcc175b8dfa1a2c173f673c1f67fa5a15041f0781a1468f48105ac81a08ee1e108fc7bb0dab826e759d49cbc67d1051cd279c46bcfae884f701c"