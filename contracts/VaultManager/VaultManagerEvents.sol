// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultManagerEvents {
    event NewVaultCreated(uint vaultId,address indexed tokenAddress);
    event Deposited(address indexed from, uint amount);
    event Withdrawn(address indexed to, uint amount);
}