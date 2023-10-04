// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

abstract contract SignCheck {
    using ECDSA for bytes32;
    mapping(address => uint) public nonces;

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function _checkData(
        address from,
        bytes memory _data,
        bytes memory _signature
    ) internal returns (bool success) {
        uint currentNonce = nonces[from];
        bytes32 hash = prefixed(
            keccak256(abi.encodePacked(_data, currentNonce))
        );
        address signer = hash.recover(_signature);

        // Increment the nonce after verification
        nonces[from] = currentNonce + 1;

        success = signer == from;
    }
}
