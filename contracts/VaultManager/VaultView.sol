// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Vault/Vault.sol";
import "./VaultState.sol";
import "./IVaultManager.sol";

abstract contract VaultView is VaultState, IVaultManager {
    function getVaultBalanceByVaultId(
        uint _vaultId
    ) public view vaultExists(_vaultId) returns (uint) {
        return Vault(vaultIdToVault[_vaultId]).tokenBalance();
    }

    function getCurrentVaultBalanceByToken(
        address _tokenAddress
    ) external view returns (uint) {
        return
            Vault(vaultIdToVault[getCurrentVaultIdByToken(_tokenAddress)])
                .tokenBalance();
    }

    function getAllVaultBalanceByToken(
        address _tokenAddress
    ) external view returns (uint balance) {
        uint[] memory vaultIds = tokenToVaultIds[_tokenAddress];
        for (uint i = 0; i < vaultIds.length; i++) {
            balance += Vault(vaultIdToVault[vaultIds[i]]).tokenBalance();
        }
    }

    function getTotalVaultsByToken(
        address _tokenAddress
    ) public view returns (uint _totalVaults) {
        _totalVaults = tokenToVaultIds[_tokenAddress].length;
    }

    function getCurrentVaultIdByToken(
        address _tokenAddress
    ) public view returns (uint vaultId) {
        require(
            getTotalVaultsByToken(_tokenAddress) > 0,
            "VaultManager: No vaults for this token"
        );
        vaultId = tokenToVaultIds[_tokenAddress][
            getTotalVaultsByToken(_tokenAddress) - 1
        ];
    }

    function vaultIdToTokenAddress(
        uint _vaultId
    ) external view override vaultExists(_vaultId) returns (address token) {
        token = Vault(vaultIdToVault[_vaultId]).tokenAddress();
    }
}