// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

abstract contract SignCheck {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    
    mapping(address => uint) public nonces;

    function _checkData(
        address from,
        bytes memory _data,
        bytes memory _signature
    ) internal returns (bool success) {
        uint currentNonce = nonces[from];
        bytes32 hash = keccak256(abi.encodePacked(_data, currentNonce))
            .toEthSignedMessageHash();
        address signer = hash.recover(_signature);
        nonces[from] = currentNonce + 1;
        success = signer == from;
    }
}
