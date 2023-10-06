// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract VaultState {
    mapping(uint => address) public vaultIdToVault;
    mapping(uint => uint) public vaultIdToTradeStartTime;
    mapping(address => uint[]) public tokenToVaultIds;
    mapping(uint => bool) public isDepositActiveForVaultId;
    mapping(uint => bool) public isWithdrawalActiveForVaultId;

    address public trustee;
    uint public totalVaults;

    modifier vaultExists(uint _vaultId) {
        require(
            vaultIdToVault[_vaultId] != address(0),
            "VaultManager: Vault not found"
        );
        _;
    }

    modifier isTrustee() {
        require(trustee == msg.sender, "VaultManager: Not Trustee");
        _;
    }

    modifier isDepositActive(uint _vaultId) {
        require(
            isDepositActiveForVaultId[_vaultId],
            "VaultManager: Deposits are frozen"
        );
        _;
    }

    modifier isWithdrawalActive(uint _vaultId) {
        require(
            isWithdrawalActiveForVaultId[_vaultId],
            "VaultManager: Withdrawals are frozen"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(
            _address != address(0),
            "VaultManager: Zero address not allowed"
        );
        _;
    }

    modifier notEOA(address _address) {
        require(_address.code.length > 0, "VaultManager: EOA not allowed");
        _;
    }
}