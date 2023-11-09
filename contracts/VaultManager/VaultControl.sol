// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@spherex-xyz/openzeppelin-solidity/contracts/access/Ownable.sol";
import "@spherex-xyz/openzeppelin-solidity/contracts/token/common/ERC2981.sol";
import "./VaultManagerEvents.sol";
import "./VaultView.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
 

abstract contract VaultControl is SphereXProtected, VaultView, VaultManagerEvents, Ownable, ERC2981 {
    /**
     * @dev will be used only once to set the trustee address initially.
     */
    function setTrustee(
        address _address
    ) external onlyOwner notZeroAddress(_address) notEOA(_address) sphereXGuardExternal(0x4c72efed) {
        require(trustee == address(0), "VaultManager: Trustee already set");
        trustee = _address;
    }

    function setTradeStartTime(
        uint _vaultId,
        uint _tradeStartTime
    ) public onlyOwner vaultExists(_vaultId) sphereXGuardPublic(0xff5b243b, 0x44334e29) {
        require( 
            _tradeStartTime == 0 ||
            _tradeStartTime > block.timestamp,
            "VaultManager: Invalid trade start time"
        );
        vaultIdToTradeStartTime[_vaultId] = _tradeStartTime;
    }

    /**
     * @dev will be used to update the trustee address. This function will need extra approvals to be called.
     */
    function updateTrustee(
        address _address
    ) external onlyOwner notZeroAddress(_address) notEOA(_address) sphereXGuardExternal(0x0e392b75) {
        require(trustee != address(0), "VaultManager: Trustee not set yet");
        trustee = _address;
    }

    function setActiveStatusForVaultId(
        uint _vaultId,
        bool _depositStatus,
        bool _withdrawStatus
    ) external onlyOwner vaultExists(_vaultId) sphereXGuardExternal(0x561abc7e) {
        bool isDepositChanged = isDepositActiveForVaultId[_vaultId] != _depositStatus;
        bool isWithdrawalChanged = isWithdrawalActiveForVaultId[_vaultId] != _withdrawStatus;
        require(
            isDepositChanged || isWithdrawalChanged,
            "VaultManager: No Change"
        );
        if (isDepositChanged) {
            isDepositActiveForVaultId[_vaultId] = _depositStatus;
        }
        if (isWithdrawalChanged) {
            isWithdrawalActiveForVaultId[_vaultId] = _withdrawStatus;
        }
        emit VaultStatusUpdate(_vaultId, _depositStatus, _withdrawStatus);
    }

    function createNewVault(
        address _tokenAddress
    ) external onlyOwner sphereXGuardExternal(0x7d670cca) returns (uint vaultId) {
        vaultId = _createNewVault(_tokenAddress);
    }

    function createNewVault(
        address _tokenAddress,
        uint _tradeStartTime
    ) external onlyOwner sphereXGuardExternal(0xdcdb1d82) returns (uint vaultId) {
        vaultId = _createNewVault(_tokenAddress);
        setTradeStartTime(vaultId, _tradeStartTime);
    }

    function createNewVault(
        address _tokenAddress,
        address _royaltyReceiver,
        uint96 _feeNumerator
    ) external onlyOwner sphereXGuardExternal(0xcc0082bd) returns (uint vaultId) {
        vaultId = _createNewVault(_tokenAddress);
        _setVaultRoyalty(
            vaultId,
            _tokenAddress,
            _royaltyReceiver,
            _feeNumerator
        );
    }

    function createNewVault(
        address _tokenAddress,
        uint _tradeStartTime,
        address _royaltyReceiver,
        uint96 _feeNumerator
    ) external onlyOwner sphereXGuardExternal(0x621f0e3e) returns (uint vaultId) {
        vaultId = _createNewVault(_tokenAddress);
        setTradeStartTime(vaultId, _tradeStartTime);
        _setVaultRoyalty(
            vaultId,
            _tokenAddress,
            _royaltyReceiver,
            _feeNumerator
        );
    }

    /// @dev used to create vaults with royalty
    /// @param _royaltyReceiver address of the royalty receiver
    /// @param _feeNumerator is set in basis points
    /// @param _feeNumerator 100 points = 1% of the sale price will be sent to the receiver
    /// @param _feeNumerator 500 points = 5% of the sale price will be sent to the receiver
    /// @param _feeNumerator 1000 points = 10% of the sale price will be sent to the receiver
    function _setVaultRoyalty(
        uint _vaultId,
        address _tokenAddress,
        address _royaltyReceiver,
        uint96 _feeNumerator
    ) private notZeroAddress(_royaltyReceiver) sphereXGuardInternal(0xf1c98a1a) {
        require(
            _feeNumerator <= _feeDenominator(),
            "VaultManager: Royalty cannot be more than 100%"
        );
        _setTokenRoyalty(_vaultId, _royaltyReceiver, _feeNumerator);
        emit VaultRoyaltySet(
            _vaultId,
            _tokenAddress,
            _royaltyReceiver,
            _feeNumerator
        );
    }

    function _createNewVault(
        address _tokenAddress
    ) private notZeroAddress(_tokenAddress) sphereXGuardInternal(0x6667d688) returns (uint vaultId) {
        Vault newVault = new Vault(_tokenAddress);
        vaultId = totalVaults++;
        vaultIdToVault[vaultId] = address(newVault);
        tokenToVaultIds[_tokenAddress].push(vaultId);
        isDepositActiveForVaultId[vaultId] = true;
        isWithdrawalActiveForVaultId[vaultId] = true;
        emit NewVaultCreated(vaultId, _tokenAddress);
    }
}