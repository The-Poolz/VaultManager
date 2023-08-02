// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract VaultRoyalty is ERC2981, Ownable{
    event DefaultRoyaltySet(address indexed receiver, uint96 indexed feeNumerator);
    event TokenRoyaltySet(uint indexed vaultId, address indexed receiver, uint96 indexed feeNumerator);

    /// @dev used to set default royalty for all vaults
    /// @param receiver address of the royalty receiver
    /// @param feeNumerator is set in basis points
    /// @param feeNumerator 100 points = 1% of the sale price will be sent to the receiver
    /// @param feeNumerator 500 points = 5% of the sale price will be sent to the receiver
    /// @param feeNumerator 1000 points = 10% of the sale price will be sent to the receiver
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner{
        _setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    /// @dev used to set royalty for a specific vault (collection of LDNFTs)
    function setRoyaltyByVaultId(uint _vaultId, address receiver, uint96 feeNumerator) external onlyOwner{
        _setTokenRoyalty(_vaultId, receiver, feeNumerator);
        emit TokenRoyaltySet(_vaultId, receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner{
        _deleteDefaultRoyalty();
        emit DefaultRoyaltySet(address(0), 0);
    }

    function resetVaultRoyalty(uint _vaultId) external onlyOwner{
        _resetTokenRoyalty(_vaultId);
        emit TokenRoyaltySet(_vaultId, address(0), 0);
    }    

}