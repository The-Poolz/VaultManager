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
        address _tokenAddress,
        uint from,
        uint count
    ) external view returns (uint balance) {
        uint[] memory vaultIds = tokenToVaultIds[_tokenAddress];
        uint totalVaultsOfToken = vaultIds.length;
        require(totalVaultsOfToken > 0, "VaultManager: No vaults for this token");
        require(count > 0, "VaultManager: Count must be greater than 0");
        require(from + count <= totalVaultsOfToken, "VaultManager: Invalid range");
        for (uint i = from; i < from + count; i++) {
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
