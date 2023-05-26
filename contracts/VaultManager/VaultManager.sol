// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVaultManager.sol";
import "./VaultManagerEvents.sol";
import "../Vault/Vault.sol";
import "poolz-helper-v2/contracts/GovManager.sol";

contract VaultManager is IVaultManager, VaultManagerEvents,GovManager{
    mapping(uint => address) public VaultIdToVault;
    mapping(address => uint[]) public TokenToVaultIds;
    uint public override TotalVaults;

    mapping(address => bool) public isPermitted;

    function setPermitted(address _address, bool _value) external onlyOwnerOrGov{
        isPermitted[_address] = _value;
    }

    function CreateNewVault(address _tokenAddress) external override onlyOwnerOrGov returns(uint vaultId){
        Vault newVault = new Vault(_tokenAddress);
        vaultId = TotalVaults;
        VaultIdToVault[vaultId] = address(newVault);
        TokenToVaultIds[_tokenAddress].push(vaultId);
        TotalVaults++;
        emit NewVaultCreated(vaultId, _tokenAddress);
    }

    function DepositeByVaultId(uint _vaultId, address from, uint _amount) external override{
        require(isPermitted[msg.sender], "VaultManager: Not permitted");
        Vault(VaultIdToVault[_vaultId]).deposit(from, _amount);
        emit Deposited(from, _amount);
    }

    function WithdrawByVaultId(uint _vaultId, address to, uint _amount) external override{
        require(isPermitted[msg.sender], "VaultManager: Not permitted");
        Vault(VaultIdToVault[_vaultId]).withdraw(to, _amount);
        emit Withdrawn(to, _amount);
    }

    function getVaultBalanceByVaultId(uint _vaultId) external override view returns(uint){
        return Vault(VaultIdToVault[_vaultId]).tokenBalance();
    }

    function getVaultBalanceByTokenAddress(address _tokenAddress) external override view returns(uint totalBalance){
        uint[] memory vaultIds = TokenToVaultIds[_tokenAddress];
        for(uint i = 0; i < vaultIds.length; i++){
            totalBalance += Vault(VaultIdToVault[vaultIds[i]]).tokenBalance();
        }
    }
}