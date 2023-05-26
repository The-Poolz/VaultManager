// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault  {
    function tokenAddress() external view returns (address);
    function tokenBalance() external view returns (uint);
    function vaultManager() external view returns (address);
    function deposit(address from, uint _amount) external;
    function withdraw(address to, uint _amount) external;
}