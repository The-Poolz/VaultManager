// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultEvents {
    event PauseTriggered(address indexed caller);
    event UnpauseTriggered(address indexed caller);

    event Deposited(address indexed from, uint amount);
    event Withdrawn(address indexed to, uint amount);
}