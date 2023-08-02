// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultManagerEvents {
    event NewVaultCreated(uint indexed vaultId, address indexed tokenAddress);
    event VaultDeleted(uint indexed vaultId, address indexed tokenAddress);
    event Deposited(
        uint indexed vaultId,
        address indexed tokenAddress,
        address indexed from,
        uint amount
    );
    event Withdrawn(
        uint indexed vaultId,
        address indexed tokenAddress,
        address indexed to,
        uint amount
    );
    event VaultRoyaltySet(
        uint indexed vaultId,
        address indexed receiver,
        uint96 indexed feeNumerator
    );
}