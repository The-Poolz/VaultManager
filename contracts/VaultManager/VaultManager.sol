// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVaultManager.sol";
import "./VaultManagerEvents.sol";
import "../Vault/Vault.sol";
import "poolz-helper-v2/contracts/GovManager.sol";

contract VaultManager is IVaultManager, VaultManagerEvents, GovManager{
    mapping(uint => address) public vaultIdToVault;
    mapping(address => uint) public tokenToVaultId;
    uint public totalVaults;
    mapping(uint => bool) public isDepositActiveForVaultId;
    mapping(uint => bool) public isWithdrawalActiveForVaultId;
    address public permittedAddress;

    modifier vaultExists(uint _vaultId){
        require(vaultIdToVault[_vaultId] != address(0), "VaultManager: Vault not found");
        _;
    }

    modifier isPermitted(){
        require(permittedAddress == msg.sender, "VaultManager: Not permitted");
        _;
    }

    modifier isDepositActive(uint _vaultId){
        require(isDepositActiveForVaultId[_vaultId], "VaultManager: Deposits are frozen");
        _;
    }

    modifier isWithdrawalActive(uint _vaultId){
        require(isWithdrawalActiveForVaultId[_vaultId], "VaultManager: Withdrawals are frozen");
        _;
    }

    function setPermitted(address _address) external onlyOwnerOrGov{
        permittedAddress = _address;
    }

    function setActiveStatusForVaultId(uint _vaultId, bool _depositStatus, bool _withdrawStatus)
        external
        onlyOwnerOrGov
        vaultExists(_vaultId)
    {
        isDepositActiveForVaultId[_vaultId] = _depositStatus;
        isWithdrawalActiveForVaultId[_vaultId] = _withdrawStatus;
    }

    function createNewVault(address _tokenAddress) external onlyOwnerOrGov returns(uint vaultId){
        Vault newVault = new Vault(_tokenAddress);
        vaultId = totalVaults++;
        vaultIdToVault[vaultId] = address(newVault);
        tokenToVaultId[_tokenAddress] = vaultId;
        isDepositActiveForVaultId[vaultId] = true;
        isWithdrawalActiveForVaultId[vaultId] = true;
        emit NewVaultCreated(vaultId, _tokenAddress);
    }

    function depositByToken(address _tokenAddress, address from, uint _amount)
        external
        override
        isPermitted
        vaultExists(tokenToVaultId[_tokenAddress])
        isDepositActive(tokenToVaultId[_tokenAddress])
        returns(uint vaultId)
    {
        vaultId = tokenToVaultId[_tokenAddress];
        address vaultAddress = vaultIdToVault[vaultId];
        require(_tokenAddress == Vault(vaultAddress).tokenAddress(), "VaultManager: token not approved");
        IERC20(_tokenAddress).transferFrom(from, vaultAddress, _amount);
        emit Deposited(vaultId, _tokenAddress, from, _amount);
    }

    function withdrawByVaultId(uint _vaultId, address to, uint _amount)
        external
        override
        isPermitted
        vaultExists(_vaultId)
        isWithdrawalActive(_vaultId)
    {
        Vault vault = Vault(vaultIdToVault[_vaultId]);
        vault.withdraw(to, _amount);
        emit Withdrawn(_vaultId, vault.tokenAddress(), to, _amount);
    }

    function getVaultBalanceByVaultId(uint _vaultId)
        external
        view
        vaultExists(_vaultId)
    returns(uint){
        return Vault(vaultIdToVault[_vaultId]).tokenBalance();
    }

    function getVaultBalanceByToken(address _tokenAddress)
        external
        view
        vaultExists(tokenToVaultId[_tokenAddress])
    returns(uint){
        return Vault(vaultIdToVault[tokenToVaultId[_tokenAddress]]).tokenBalance();
    }

    function vaultIdToTokenAddress(
        uint _vaultId
    )
        external
        view
        override
        vaultExists(_vaultId)
        returns (address token)
    {
        token = Vault(vaultIdToVault[_vaultId]).tokenAddress();
    }
}