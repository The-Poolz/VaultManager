// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVault.sol";
import "@spherex-xyz/poolz-helper-v2/contracts/ERC20Helper.sol"; 
import {SphereXProtectedBase} from "@spherex-xyz/contracts/src/SphereXProtectedBase.sol";
 

contract Vault is SphereXProtectedBase, IVault, ERC20Helper {
    address public override tokenAddress;
    address public override vaultManager;

    constructor(address _tokenAddress, address spherex_admin, address spherex_operator, address spherex_engine) {
        __SphereXProtectedBase_init(spherex_admin, spherex_operator, spherex_engine);
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

    function withdraw(address to, uint _amount) external override onlyManager sphereXGuardExternal(0xc4f7cea1) {
        require(tokenBalance() >= _amount, "Vault: Not enough balance");
        TransferToken(tokenAddress, to, _amount);
    }
}
