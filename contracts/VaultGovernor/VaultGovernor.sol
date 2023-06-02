// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultGovernorState.sol";
import "./VaultGovernorManagable.sol";
import "../VaultManager/IVaultManager.sol";

contract VaultGovernor is VaultGovernorState, VaultGovernorManagable {

    function createNewPermitProposal(
        address _vaultUser, // The user that will be permitted
        bool _permissionStatus // The permission status that will be set
    ) external onlyPermitterOrAdmin returns(uint proposalId){
        proposalId = TotalPermitProposals++;
        PermitProposal storage proposal = PermitProposals[proposalId];
        proposal.vaultUser = _vaultUser;
        proposal.permissionStatus = _permissionStatus;
        proposal.isExecuted = false;
        proposal.approvals = 1; // creating a proposal also approves it
        proposal.isApproved[msg.sender] = true;
        emit NewPermitProposal(proposalId, msg.sender, _vaultUser, _permissionStatus);
        executePermitProposal(proposalId);
    }

    function getPermitProposalById(uint _proposalId) external view returns(
        address vaultUser,
        bool permissionStatus,
        bool isExecuted,
        uint8 approvals
    ){
        PermitProposal storage proposal = PermitProposals[_proposalId];
        vaultUser = proposal.vaultUser;
        permissionStatus = proposal.permissionStatus;
        isExecuted = proposal.isExecuted;
        approvals = proposal.approvals;
    }

    function approvePermitProposal(uint _proposalId) external onlyPermitterOrAdmin{
        PermitProposal storage proposal = PermitProposals[_proposalId];
        require(proposal.isExecuted == false, "VaultGov: Proposal Already Executed");
        require(proposal.isApproved[msg.sender] == false, "VaultGov: You have already approved this Proposal");
        proposal.approvals++;
        proposal.isApproved[msg.sender] = true;
        emit PermitProposalApproved(_proposalId, msg.sender, proposal.vaultUser, proposal.permissionStatus, proposal.approvals);
        executePermitProposal(_proposalId);
    }

    function executePermitProposal(uint _proposalId) private returns(bool isExecuted) {
        PermitProposal storage proposal = PermitProposals[_proposalId];
        if(proposal.approvals == ApprovalsNeededForPermit){
            proposal.isExecuted = true;
            IVaultManager(VaultManagerAddress).setPermitted(proposal.vaultUser, proposal.permissionStatus);
            emit PermitProposalExecuted(_proposalId, msg.sender, proposal.vaultUser, proposal.permissionStatus);
            return true;
        }
        return false;
    }

    function createNewTokenProposal(
        address _tokenAddress, // The address of the token
        bool _permissionStatus // The permission status that will be set
    ) external onlyPermitterOrAdmin returns(uint proposalId){
        proposalId = TotalTokenProposals++;
        TokenProposal storage proposal = TokenProposals[proposalId];
        proposal.tokenAddress = _tokenAddress;
        proposal.permissionStatus = _permissionStatus;
        proposal.isExecuted = false;
        proposal.approvals = 1; // creating a proposal also approves it
        proposal.isApproved[msg.sender] = true;
        emit NewTokenProposal(proposalId, msg.sender, _tokenAddress, _permissionStatus);
        executeTokenProposal(proposalId);
    }

    function getTokenProposalById(uint _proposalId) external view returns(
        address tokenAddress,
        bool permissionStatus,
        bool isExecuted,
        uint8 approvals
    ){
        TokenProposal storage proposal = TokenProposals[_proposalId];
        tokenAddress = proposal.tokenAddress;
        permissionStatus = proposal.permissionStatus;
        isExecuted = proposal.isExecuted;
        approvals = proposal.approvals;
    }

    function approveTokenProposal(uint _proposalId) external onlyPermitterOrAdmin{
        TokenProposal storage proposal = TokenProposals[_proposalId];
        require(proposal.isExecuted == false, "VaultGov: Proposal Already Executed");
        require(proposal.isApproved[msg.sender] == false, "VaultGov: You have already approved this Proposal");
        proposal.approvals++;
        proposal.isApproved[msg.sender] = true;
        emit TokenProposalApproved(_proposalId, msg.sender, proposal.tokenAddress, proposal.permissionStatus, proposal.approvals);
        executeTokenProposal(_proposalId);
    }

    function executeTokenProposal(uint _proposalId) private returns(bool isExecuted) {
        TokenProposal storage proposal = TokenProposals[_proposalId];
        if(proposal.approvals == ApprovalNeededForCreate){
            proposal.isExecuted = true;
            if(proposal.permissionStatus){
                IVaultManager(VaultManagerAddress).CreateNewVault(proposal.tokenAddress);
            } else {
                IVaultManager(VaultManagerAddress).DeleteVault(proposal.tokenAddress);
            }
            emit TokenProposalExecuted(_proposalId, msg.sender, proposal.tokenAddress, proposal.permissionStatus);
            return true;
        }
        return false;
    }

    function SetVaultManagerGovernor(address _newGov) external onlyAdmin {
        IVaultManager(VaultManagerAddress).setGovernor(_newGov);
    }

}