// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";

contract VaultFactory{
    function CreateNewVault(address _tokenAddress) public returns(address){
        Vault newVault = new Vault(_tokenAddress);
        return address(newVault);
    }
}