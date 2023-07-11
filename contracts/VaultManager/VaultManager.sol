// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVaultManager.sol";
import "./VaultManagerEvents.sol";
import "../Vault/Vault.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "poolz-helper-v2/contracts/Array.sol";

contract VaultManager is IVaultManager, VaultManagerEvents, GovManager{
    mapping(uint => address) public vaultIdToVault;
    mapping(address => uint[]) public tokenToVaultIds;
    mapping(uint => bool) public isDepositActiveForVaultId;
    mapping(uint => bool) public isWithdrawalActiveForVaultId;
    address[] public allTokens; // just an array of all tokens
    address public trustee;
    uint public totalVaults;

    modifier vaultExists(uint _vaultId){
        require(vaultIdToVault[_vaultId] != address(0), "VaultManager: Vault not found");
        _;
    }

    modifier isTrustee(){
        require(trustee == msg.sender, "VaultManager: Not Trustee");
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

    function setTrustee(address _address) external onlyOwnerOrGov{
        require(_address.code.length > 0, "VaultManager: EOA not allowed");
        trustee = _address;
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
        tokenToVaultIds[_tokenAddress].push(vaultId);
        Array.addIfNotExsist(allTokens, _tokenAddress);
        isDepositActiveForVaultId[vaultId] = true;
        isWithdrawalActiveForVaultId[vaultId] = true;
        emit NewVaultCreated(vaultId, _tokenAddress);
    }

    /**
     * @dev Will be used by the Trustee to deposit tokens to the vault.
     * @param _from Trustee is responsible to provide the correct _from address.
     */
    function depositByToken(address _tokenAddress, address _from, uint _amount)
        external
        override
        isTrustee
        isDepositActive(getCurrentVaultIdByToken(_tokenAddress))
        returns(uint vaultId)
    {   
        require(tx.origin == _from, "VaultManager: Only origin can deposit");
        vaultId = getCurrentVaultIdByToken(_tokenAddress);
        address vaultAddress = vaultIdToVault[vaultId];
        assert(_tokenAddress == Vault(vaultAddress).tokenAddress());
        IERC20(_tokenAddress).transferFrom(_from, vaultAddress, _amount);
        emit Deposited(vaultId, _tokenAddress, _from, _amount);
    }

    /**
     * @dev Will be used by the Trustee to deposit tokens to the vault.
     * @param _to Trustee is responsible to provide the correct _to address.
     */
    function withdrawByVaultId(uint _vaultId, address _to, uint _amount)
        external
        override
        isTrustee
        vaultExists(_vaultId)
        isWithdrawalActive(_vaultId)
    {
        Vault vault = Vault(vaultIdToVault[_vaultId]);
        vault.withdraw(_to, _amount);
        emit Withdrawn(_vaultId, vault.tokenAddress(), _to, _amount);
    }

    function getVaultBalanceByVaultId(uint _vaultId)
        public
        view
        vaultExists(_vaultId)
    returns(uint){
        return Vault(vaultIdToVault[_vaultId]).tokenBalance();
    }

    function getCurrentVaultBalanceByToken(address _tokenAddress)
        external
        view
    returns(uint){
        return Vault(vaultIdToVault[getCurrentVaultIdByToken(_tokenAddress)]).tokenBalance();
    }

    function getAllVaultBalanceByToken(address _tokenAddress)
        external
        view
        returns(uint balance)
    {
        uint[] memory vaultIds = tokenToVaultIds[_tokenAddress];
        for(uint i=0; i < vaultIds.length; i++){
            balance += Vault(vaultIdToVault[vaultIds[i]]).tokenBalance();
        }
    }

    function getTotalVaultsByToken(address _tokenAddress) public view returns(uint _totalVaults) {
        _totalVaults = tokenToVaultIds[_tokenAddress].length;
    }

    function getCurrentVaultIdByToken(address _tokenAddress)
        public
        view
        returns(uint vaultId)
    {
        require(getTotalVaultsByToken(_tokenAddress) > 0, "VaultManager: No vaults for this token");
        vaultId = tokenToVaultIds[_tokenAddress][getTotalVaultsByToken(_tokenAddress) - 1];
    }

    function getAllTokens() external view returns(address[] memory){
        return allTokens;
    }

    function getTotalNumberOfTokens() external view returns(uint){
        return allTokens.length;
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