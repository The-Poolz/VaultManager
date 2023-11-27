// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SignCheck.sol";
import "./VaultControl.sol";
import "@ironblocks/firewall-consumer/contracts/FirewallConsumer.sol";

contract VaultManager is
    VaultControl,
    SignCheck,
    ReentrancyGuard
{
    /*
     * @dev Will be used by the Trustee to deposit tokens to the vault.
     * @param _from Trustee is responsible to provide the correct _from address.
     */
    function depositByToken(
        address _tokenAddress,
        uint _amount
    )
        external
        override
        firewallProtected
        nonReentrant
        isTrustee
        isDepositActive(getCurrentVaultIdByToken(_tokenAddress))
        returns (uint vaultId)
    {
        vaultId = _deposit(_tokenAddress, _amount, trustee);
    }

    function safeDeposit(
        address _tokenAddress,
        uint _amount,
        address _from,
        bytes memory _signature
    )
        external
        override
        firewallProtected
        nonReentrant
        isTrustee
        isDepositActive(getCurrentVaultIdByToken(_tokenAddress))
        returns (uint vaultId)
    {
        bytes memory dataToCheck = abi.encodePacked(_tokenAddress, _amount);
        require(
            _checkData(_from, dataToCheck, _signature),
            "VaultManager: Only origin can deposit"
        );
        vaultId = _deposit(_tokenAddress, _amount, _from);
    }

    function _deposit(
        address _tokenAddress,
        uint _amount,
        address _depositFrom
    )
        private
        firewallProtectedSig(0x94238929)
        returns (uint vaultId)
    {
        vaultId = getCurrentVaultIdByToken(_tokenAddress);
        uint balanceBefore = getVaultBalanceByVaultId(vaultId);
        address vaultAddress = vaultIdToVault[vaultId];
        assert(_tokenAddress == Vault(vaultAddress).tokenAddress());
        IERC20(_tokenAddress).transferFrom(_depositFrom, vaultAddress, _amount);
        emit Deposited(vaultId, _tokenAddress, _amount);
        assert(getVaultBalanceByVaultId(vaultId) == balanceBefore + _amount);
    }

    /**
     * @dev Will be used by the Trustee to deposit tokens to the vault.
     * @param _to Trustee is responsible to provide the correct _to address.
     */
    function withdrawByVaultId(
        uint _vaultId,
        address _to,
        uint _amount
    )
        external
        override
        firewallProtected
        isTrustee
        nonReentrant
        vaultExists(_vaultId)
        isWithdrawalActive(_vaultId)
    {
        uint balanceBefore = getVaultBalanceByVaultId(_vaultId);
        Vault vault = Vault(vaultIdToVault[_vaultId]);
        vault.withdraw(_to, _amount);
        emit Withdrawn(_vaultId, vault.tokenAddress(), _to, _amount);
        assert(getVaultBalanceByVaultId(_vaultId) == balanceBefore - _amount);
    }
}