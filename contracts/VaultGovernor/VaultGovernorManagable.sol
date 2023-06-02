// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract VaultGovernorManagable is AccessControl {
    bytes32 public constant PERMITTER_ROLE = keccak256("PERMITTER_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    address public VaultManagerAddress;

    uint8 public ApprovalsNeededForPermit;
    uint8 public ApprovalNeededForCreate;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ApprovalsNeededForPermit = 2;
        ApprovalNeededForCreate = 1;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "VaultGovernor: Not admin"
        );
        _;
    }

    modifier onlyCreatorOrAdmin() {
        require(
            hasRole(CREATOR_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "VaultGovernor: Not creator or admin"
        );
        _;
    }

    modifier onlyPermitterOrAdmin() {
        require(
            hasRole(PERMITTER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "VaultGovernor: Not permitter or admin"
        );
        _;
    }

    function grantPermitterRole(address _address) external {
        grantRole(PERMITTER_ROLE, _address);
    }

    function revokePermitterRole(address _address) external {
        revokeRole(PERMITTER_ROLE, _address);
    }

    function grantCreatorRole(address _address) external {
        grantRole(CREATOR_ROLE, _address);
    }

    function revokeCreatorRole(address _address) external {
        revokeRole(CREATOR_ROLE, _address);
    }

    function updateAdminRole(address _newAdmin) external {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setVaultManagerAddress(address _address) external onlyAdmin {
        VaultManagerAddress = _address;
    }

    function setApprovalsNeededForPermit(uint8 _approvals) external onlyPermitterOrAdmin {
        ApprovalsNeededForPermit = _approvals;
    }

    function setApprovalNeededForCreate(uint8 _approvals) external onlyCreatorOrAdmin {
        ApprovalNeededForCreate = _approvals;
    }

}