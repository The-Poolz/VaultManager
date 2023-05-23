// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVault.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";

contract Vault is IVault, ERC20Helper{
    address public override tokenAddress;
    uint public override tokenBalance;

    mapping(address => bool) public isPermitted;

    constructor(address _tokenAddress){
        tokenAddress = _tokenAddress;
        isPermitted[msg.sender] = true;
    }

    modifier needsPermission(){
        require(isPermitted[msg.sender] == true, "Not permitted");
        _;
    }

    function deposit(address from, uint _amount) external override needsPermission {
        TransferInToken(tokenAddress, from, _amount);
        tokenBalance += _amount;
    }

    function withdraw(address to, uint _amount) external override needsPermission {
        require(tokenBalance >= _amount, "Not enough balance");
        TransferToken(tokenAddress, to, _amount);
        tokenBalance -= _amount;
    }
}
