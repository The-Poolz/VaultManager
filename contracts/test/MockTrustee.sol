// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../VaultManager/IVaultManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@ironblocks/firewall-consumer/contracts/FirewallConsumer.sol";

contract MockTrustee is FirewallConsumer {
    IVaultManager public vaultManager;

    constructor(address _vaultManager) {
        vaultManager = IVaultManager(_vaultManager);
    }

    function deposit(
        address _tokenAddress,
        uint _amount
    ) external firewallProtected returns (uint vaultId) {
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        IERC20(_tokenAddress).approve(address(vaultManager), _amount);
        vaultId = vaultManager.depositByToken(_tokenAddress, _amount);
    }

    function safeDeposit(
        address _tokenAddress,
        uint _amount,
        address _from,
        bytes memory _signature
    ) external firewallProtected returns (uint vaultId){
        vaultId = vaultManager.safeDeposit(_tokenAddress, _amount, _from, _signature);
    }

    function withdraw(uint _vaultId, address to, uint _amount) external firewallProtected {
        vaultManager.withdrawByVaultId(_vaultId, to, _amount);
    }
}
