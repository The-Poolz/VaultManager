// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVault.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";

contract Vault is IVault{
    address public tokenAddress;
    uint public tokenBalance;

    mapping(address => bool) public permittedDepositors;
    mapping(address => bool) public permittedWithdrawers;

    constructor(address _tokenAddress){
        tokenAddress = _tokenAddress;
        permittedDepositors[msg.sender] = true;
        permittedWithdrawers[msg.sender] = true;
    }

    function deposit(uint _amount) external override {
        require(permittedDepositors[msg.sender] == true, "Not permitted to deposit");
        TransferInToken(tokenAddress, msg.sender, _amount);
        tokenBalance += _amount;
    }

    function withdraw(address _receiver, uint _amount) external override{
        require(permittedWithdrawers[msg.sender] == true, "Not permitted to withdraw");
        require(tokenBalance >= _amount, "Not enough balance");
        TransferToken(tokenAddress, _receiver, _amount);
        tokenBalance -= _amount;
    }
}