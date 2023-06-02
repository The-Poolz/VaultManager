// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultGovernorState {
    struct PermitProposal {
        address vaultUser;
        bool permissionStatus;
        bool isExecuted;
        uint8 approvals;
        mapping(address => bool) isApproved;
    }

    mapping(uint => PermitProposal) public PermitProposals;
    uint public TotalPermitProposals;

    struct TokenProposal {
        address tokenAddress;
        bool permissionStatus;
        bool isExecuted;
        uint8 approvals;
        mapping(address => bool) isApproved;
    }

    mapping(uint => TokenProposal) public TokenProposals;
    uint public TotalTokenProposals;

    event NewPermitProposal(
        uint ProposalId,
        address indexed Creator,
        address indexed VaultUser,
        bool PermissionStatus
    );

    event PermitProposalApproved(
        uint ProposalId,
        address indexed Approver,
        address indexed VaultUser,
        bool PermissionStatus,
        uint8 approvals
    );

    event PermitProposalExecuted(
        uint ProposalId,
        address indexed Executer,
        address indexed VaultUser,
        bool PermissionStatus
    );

    event NewTokenProposal(
        uint proposalId,
        address indexed Creator,
        address indexed tokenAddress,
        bool permissionStatus
    );

    event TokenProposalApproved(
        uint proposalId,
        address indexed approver,
        address indexed tokenAddress,
        bool permissionStatus,
        uint8 approvals
    );

    event TokenProposalExecuted(
        uint proposalId,
        address indexed executer,
        address indexed tokenAddress,
        bool permissionStatus
    );

}