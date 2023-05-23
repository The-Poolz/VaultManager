// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVault.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";

contract Vault is IVault, ERC20Helper{
    address public override tokenAddress;
    uint public override tokenBalance;

    mapping(address => bool) public override permittedDepositors;
    mapping(address => bool) public override permittedWithdrawers;

    constructor(address _tokenAddress){
        tokenAddress = _tokenAddress;
        permittedDepositors[msg.sender] = true;
        permittedWithdrawers[msg.sender] = true;
    }

    function deposit(address from, uint _amount) external override { 
        require(permittedDepositors[msg.sender] == true, "Not permitted to deposit");
        TransferInToken(tokenAddress, from, _amount);
        tokenBalance += _amount;
    }

    function withdraw(address to, uint _amount) external override { 
        require(permittedWithdrawers[msg.sender] == true, "Not permitted to withdraw");
        require(tokenBalance >= _amount, "Not enough balance");
        TransferToken(tokenAddress, to, _amount);
        tokenBalance -= _amount;
    }
}
