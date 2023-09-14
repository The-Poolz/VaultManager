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

```
git clone https://github.com/The-Poolz/VaultManager.git
```

2. Install the dependencies:

```
npm install
```

3. Run the Hardhat test:

```
npx hardhat test
```

## Usage

After deploying the contracts, the owner (the deployer) can perform various operations.

### From an External Contract

#### Deposit

To deposit tokens into a vault, the external contract should call `depositByToken` from `VaultManager.sol`. Make sure that `msg.sender` is set to the `_from` address.

#### Withdraw

To withdraw tokens, the external contract ` calls the `withdraw` function.

### Owner Functionalities

If you are the owner of the deployed contracts, you have the following additional functionalities:

#### In VaultManager.sol

1. **Set Trustee**: Must be called to finish the setup and can only be called once. After that, use `updateTrustee` to change the trustee.
2. **Set Trade Start Time**: Can be used to change the trade start time initially set during vault creation with `createNewVault`.
3. **Set Vault Royalty**: Can be used to change the royalty details initially set during vault creation with `createNewVault`.
4. **Create New Vault**: This function has multiple overloads, allowing you to create new vaults with different configurations.
5. **Update Trustee**: You can update the trustee address using `updateTrustee`.


#### In Vault.sol

The Vault is an internal contract that is managed solely by its creator, the VaultManager contract. No one else can interact with it directly. It serves as a small internal part responsible for specific functionalities like `withdraw`.

1. **Withdraw**: The Vault Manager, which is the entity that creates the vault, has the ability to withdraw tokens to a specified address using the `withdraw` function.


### Role of the Trustee

Only the trustee can use the tokens stored in the vaults, not the owner.

## Code Overview

### Solidity Contracts

- [IVault.sol](./contracts/Vault/IVault.sol): Defines the interface for Vault contract.
- [Vault.sol](./contracts/Vault/Vault.sol): Implements the Vault functionalities.
- [IVaultManager.sol](./contracts/VaultManager/IVaultManager.sol): Defines the interface for Vault Manager.
- [VaultManager.sol](./contracts/VaultManager/VaultManager.sol): Implements the Vault Manager functionalities.
- [VaultManagerEvents.sol](./contracts/VaultManager/VaultManagerEvents.sol): Contains events for Vault Manager.

### Tests

- [1_Vault.ts](./test/1_Vault.ts): Test cases for Vault.
- [2_VaultManager.ts](./test/2_VaultManager.ts): Test cases for Vault Manager.
- [3_VaultManagerFail.ts](./test/3_VaultManagerFail.ts): Negative test cases for Vault Manager.

## Contributing

Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License.
