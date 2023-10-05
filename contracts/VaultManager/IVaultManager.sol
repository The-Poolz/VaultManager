// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVaultManager {
    function depositByToken(
        address _tokenAddress,
        uint _amount
    ) external returns (uint vaultId);

    function safeDeposit (
        address _tokenAddress,
        uint _amount,
        address _from,
        bytes memory _signature
    ) external returns (uint vaultId);

    function withdrawByVaultId(
        uint _vaultId,
        address to,
        uint _amount
    ) external;

    function vaultIdToTokenAddress(
        uint _vaultId
    ) external view returns (address token);
}
