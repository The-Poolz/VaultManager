// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVault.sol";
import "./VaultEvents.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Vault is IVault, VaultEvents, ERC20Helper, Pausable{
    address public override tokenAddress;
    uint public override tokenBalance;

    mapping(address => bool) public override isPermitted;

    constructor(address _tokenAddress){
        tokenAddress = _tokenAddress;
        isPermitted[msg.sender] = true;
    }

    modifier needsPermission(){
        require(isPermitted[msg.sender] == true, "Not permitted");
        _;
    }

    function deposit(address from, uint _amount) external override needsPermission whenNotPaused {
        TransferInToken(tokenAddress, from, _amount);
        tokenBalance += _amount;
        emit Deposited(from, _amount);
    }

    function withdraw(address to, uint _amount) external override needsPermission whenNotPaused {
        require(tokenBalance >= _amount, "Not enough balance");
        TransferToken(tokenAddress, to, _amount);
        tokenBalance -= _amount;
        emit Withdrawn(to, _amount);
    }

    function checkBalanceAndPauseIfMismatched() external {
        uint realBalance = IERC20(tokenAddress).balanceOf(address(this));
        if(realBalance != tokenBalance) {
            _pause();
            emit PauseTriggered(msg.sender); // Emit the event
        } else if(paused()) { // If the contract is paused and the balances match, unpause it
            _unpause();
            emit UnpauseTriggered(msg.sender); // Emit the event
        }
    }
}
