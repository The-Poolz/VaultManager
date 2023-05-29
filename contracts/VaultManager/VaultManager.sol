// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVaultManager.sol";
import "./VaultManagerEvents.sol";
import "../Vault/Vault.sol";
import "poolz-helper-v2/contracts/GovManager.sol";

contract VaultManager is IVaultManager, VaultManagerEvents,GovManager{
    mapping(uint => address) public VaultIdToVault;
    mapping(address => uint) public TokenToVaultId;
    uint public override TotalVaults;

    mapping(address => bool) public isPermitted;

    modifier vaultExists(uint _vaultId){
        require(VaultIdToVault[_vaultId] != address(0), "VaultManager: Vault not found");
        _;
    }

    function setPermitted(address _address, bool _value) external onlyOwnerOrGov{
        isPermitted[_address] = _value;
    }

    function CreateNewVault(address _tokenAddress) external override onlyOwnerOrGov returns(uint vaultId){
        Vault newVault = new Vault(_tokenAddress);
        vaultId = TotalVaults;
        VaultIdToVault[vaultId] = address(newVault);
        TokenToVaultId[_tokenAddress] = vaultId;
        TotalVaults++;
        emit NewVaultCreated(vaultId, _tokenAddress);
    }

    function DepositeByToken(address _tokenAddress, address from, uint _amount)
        external
        override
        vaultExists(TokenToVaultId[_tokenAddress])
        returns(uint vaultId)
    {
        require(isPermitted[msg.sender], "VaultManager: Not permitted");
        vaultId = TokenToVaultId[_tokenAddress];
        Vault(VaultIdToVault[vaultId]).deposit(from, _amount);
        emit Deposited(vaultId, _tokenAddress, from, _amount);
    }

    function WithdrawByVaultId(uint _vaultId, address to, uint _amount)
        external
        override
        vaultExists(_vaultId)
    {
        require(isPermitted[msg.sender], "VaultManager: Not permitted");
        Vault vault = Vault(VaultIdToVault[_vaultId]);
        vault.withdraw(to, _amount);
        emit Withdrawn(_vaultId, vault.tokenAddress(), to, _amount);
    }

    function getVaultBalanceByVaultId(uint _vaultId)
        external
        view
        override
        vaultExists(_vaultId)
    returns(uint){
        return Vault(VaultIdToVault[_vaultId]).tokenBalance();
    }

    function getVaultBalanceByToken(address _tokenAddress)
        external
        view
        override
        vaultExists(TokenToVaultId[_tokenAddress])
    returns(uint){
        return Vault(VaultIdToVault[TokenToVaultId[_tokenAddress]]).tokenBalance();
    }
}