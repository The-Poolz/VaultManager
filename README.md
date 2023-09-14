# Vault Manager

## Description

Vault Manager is a smart contract project that helps other contracts manage ERC20 tokens and maintain whitelists for each token.

### Features

- Management of ERC20 tokens
- Whitelisting functionalities
- Owner-based actions

## Prerequisites

- [Hardhat](https://hardhat.org/getting-started/#overview)

## Installation

1. Clone the repository:

\```
git clone https://github.com/The-Poolz/VaultManager.git
\```

2. Install the dependencies:

\```
npm install
\```

3. Run the Hardhat test:

\```
npx hardhat test
\```

## Usage

After deploying the contracts, the owner (the deployer) can perform various operations.

### From an External Contract

#### Deposit

To deposit tokens into a vault, the external contract should call `depositByToken` from `VaultManager.sol`. Make sure that `tx.origin` is set to the `_from` address.

#### Withdraw

To withdraw tokens, the external contract must send `msg.sender` to the `withdraw` function.

### Owner Functionalities

If you are the owner of the deployed contracts, you have the following additional functionalities:

1. **Set Trade Start Time**: You can set the trade start time for a specific vault ID using `setTradeStartTime`.
2. **Create New Vault**: You can create a new vault for a given token address using `createNewVault`. This function also has an overload to include a trade start time.

## Code Overview

### Solidity Contracts

- [IVault.sol](./contracts/IVault.sol): Defines the interface for Vault contract.
- [Vault.sol](./contracts/Vault.sol): Implements the Vault functionalities.
- [IVaultManager.sol](./contracts/IVaultManager.sol): Defines the interface for Vault Manager.
- [VaultManager.sol](./contracts/VaultManager.sol): Implements the Vault Manager functionalities.
- [VaultManagerEvents.sol](./contracts/VaultManagerEvents.sol): Contains events for Vault Manager.

### Tests

- [1_Vault.ts](./test/1_Vault.ts): Test cases for Vault.
- [2_VaultManager.ts](./test/2_VaultManager.ts): Test cases for Vault Manager.
- [3_VaultManagerFail.ts](./test/3_VaultManagerFail.ts): Negative test cases for Vault Manager.

## Contributing

Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License.
