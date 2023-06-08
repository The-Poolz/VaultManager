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

    modifier isPermittedToCall(){
        require(isPermitted[msg.sender], "VaultManager: Not permitted");
        _;
    }

    function setPermitted(address _address, bool _value) external onlyOwnerOrGov{
        isPermitted[_address] = _value;
    }

    function CreateNewVault(address _tokenAddress) external override onlyOwnerOrGov returns(uint vaultId){
        Vault newVault = new Vault(_tokenAddress);
        vaultId = TotalVaults++;
        VaultIdToVault[vaultId] = address(newVault);
        TokenToVaultId[_tokenAddress] = vaultId;
        emit NewVaultCreated(vaultId, _tokenAddress);
    }
    
    function DeleteVault(address _tokenAddress)
        external
        override
        onlyOwnerOrGov
        vaultExists(TokenToVaultId[_tokenAddress])
        returns (uint vaultId)
    {
        Vault vault = Vault(VaultIdToVault[TokenToVaultId[_tokenAddress]]);
        require(vault.tokenBalance() == 0, "VaultManager: Vault not empty");
        vaultId = TokenToVaultId[_tokenAddress];
        delete VaultIdToVault[vaultId];
        delete TokenToVaultId[_tokenAddress];
        emit VaultDeleted(vaultId, _tokenAddress);
    }

    function DepositByToken(address _tokenAddress, address from, uint _amount)
        external
        override
        isPermittedToCall
        vaultExists(TokenToVaultId[_tokenAddress])
        returns(uint vaultId)
    {
        vaultId = TokenToVaultId[_tokenAddress];
        address vaultAddress = VaultIdToVault[vaultId];
        require(_tokenAddress == Vault(vaultAddress).tokenAddress(), "VaultManager: token not approved");
        IERC20(_tokenAddress).transferFrom(from, vaultAddress, _amount);
        emit Deposited(vaultId, _tokenAddress, from, _amount);
    }

    function WithdrawByVaultId(uint _vaultId, address to, uint _amount)
        external
        override
        isPermittedToCall
        vaultExists(_vaultId)
    {
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