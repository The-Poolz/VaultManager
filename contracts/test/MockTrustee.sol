// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../VaultManager/IVaultManager.sol";

contract MockTrustee{
    IVaultManager public vaultManager;

    constructor(address _vaultManager){
        vaultManager = IVaultManager(_vaultManager);
    }

    function deposit(address _tokenAddress, address from, uint _amount) external returns (uint vaultId){
        vaultId = vaultManager.depositByToken(_tokenAddress, from, _amount);
    }

    function withdraw(uint _vaultId, address to, uint _amount) external{
        vaultManager.withdrawByVaultId(_vaultId, to, _amount);
    }
}