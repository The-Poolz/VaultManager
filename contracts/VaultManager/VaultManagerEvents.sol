// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VaultManagerEvents {
    event NewVaultCreated(uint indexed vaultId, address indexed tokenAddress);
    event VaultDeleted(uint indexed vaultId, address indexed tokenAddress);
    event Deposited(
        uint indexed vaultId,
        address indexed tokenAddress,
        uint amount
    );
    event Withdrawn(
        uint indexed vaultId,
        address indexed tokenAddress,
        address indexed to,
        uint amount
    );
    event VaultRoyaltySet(
        uint vaultId,
        address indexed tokenAddress,
        address indexed receiver,
        uint96 indexed feeNumerator
    );
    event VaultStatusUpdate (
        uint indexed vaultId,
        bool indexed depositStatus,
        bool indexed withdrawStatus
    );
}
