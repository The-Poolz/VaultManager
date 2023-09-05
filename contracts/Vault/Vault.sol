// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVault.sol";
import "@poolzfinance/poolz-helper-v2/contracts/ERC20Helper.sol";

contract Vault is IVault, ERC20Helper{
    address public override tokenAddress;
    address public override vaultManager;

    constructor(address _tokenAddress){
        tokenAddress = _tokenAddress;
        vaultManager = msg.sender;
    }

    modifier onlyManager(){
        require(msg.sender == vaultManager, "Vault: Only manager can call this function");
        _;
    }

    function tokenBalance() public view override returns(uint) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function withdraw(address to, uint _amount) external override onlyManager {
        require(tokenBalance() >= _amount, "Vault: Not enough balance");
        TransferToken(tokenAddress, to, _amount);
    }
}
