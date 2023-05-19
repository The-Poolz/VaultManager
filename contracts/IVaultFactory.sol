// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";

interface IVaultFactory{
    function CreateNewVault(address _tokenAddress) external returns(address);
}