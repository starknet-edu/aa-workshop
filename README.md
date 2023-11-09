# Starknet’s Account Abstraction Workshop

In this workshop you will learn how to create an account contract with a single signer that uses the STARK-friendly elliptic curve to sign transactions. The final code is inspired by Open Zeppelin’s account contract.

After completing each step, run the associated script to verify it has been implemented correctly.

## Setup

1. Install Scarb 2.3.1 with `asdf` ([instructions](https://docs.swmansion.com/scarb/download.html#install-via-asdf))
1. Install Starknet Foundry ([instructions](https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html))
1. Clone this repository

## Step 1

### Goal

Collect the `public_key` associated with a signer that is passed to the `constructor`, and make it public through a function also called `public_key`.

### Verification

When completed, run the script below to verify your implementation.

```
$ scarb run verify_step1
```

### Hints
* A `public_key` is defined with a single felt

## Step 2

If you fell behind, catch up to this step by running the command below.

```
$ git stash && git checkout -b step2 origin/step2
```

### Goal

Implement the function `is_valid_signature` as defined by the [SNIP-6](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-6.md) standard.

### Requirements

* If the signature was created by the signer associated with the account contract the function should return the short string `'VALID'`.
* If the signature was created by a signer not associated with the account contract, the function should return any other felt that is not the short string `'VALID'`.

### Verification

When completed, run the script below to verify your implementation.

```
$ scarb run verify_step2
```

### Hints

* Use the stored `public_key` to check the signature.
* A "short string" is just an ascii representation of a single felt.
* You can check signatures on the STARK-friendly curve with the syscall `check_ecdsa_signature` available in the `ecdsa` module.
* The short string `'VALID'` can be hardcoded or read from the module `starknet::VALIDATED`.

## Step 3

If you fell behind, catch up to this step by running the command below.

```
$ git stash && git checkout -b step3 origin/step3
```

### Goal

Implement the function `__validate__` as defined by the [SNIP-6](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-6.md) standard. This function is similar to `is_valid_signature` but instead of expecting the signature to be passed as an argument it verifies the transaction's signature.

### Requirements

* If the transaction signature was created by the signer associated with the account contract the function should return the short string `'VALID'`.
* If the transaction signature was created by a signer not associated with the account contract, the transaction should be halted and reverted with an error message.

### Verification

When completed, run the script below to verify your implementation.

```
$ scarb run verify_step3
```

### Hints

* You can read the transaction details which includes the transaction signature using the syscall `get_tx_info` from the `starknet` module.
* You can stop and revert a transaction with an error message using the `assert` function.
* The `Call` struct can be found in the module `starknet::account`.

## Step 4

If you fell behind, catch up to this step by running the command below.

```
$ git stash && git checkout -b step4 origin/step4
```

### Goal

Protect the `__validate__` function by making it callable only by the protocol which uses the zero address.

### Requirements

* If the function is invoked by any other address, the transaction should be halted and reverted with an error message.

### Verification

When completed, run the script below to verify your implementation.

```
$ scarb run verify_step4
```

### Hints

* You can read who the caller is by using the syscall `get_caller_address` available in the `starknet` module.

## Step 5

If you fell behind, catch up to this step by running the command below.

```
$ git stash && git checkout -b step5 origin/step5
```

### Goal

Implement the functions `__validate_declare__` and `__validate_deploy__` with the exact same logic as `__validate__` and make them publicly accessible. The signature of both functions is shown below.

```cairo
fn __validate_declare__(
    self: @ContractState,
    class_hash: felt252
) -> felt252

fn __validate_deploy__(
    self: @ContractState,
    class_hash: felt252,
    salt: felt252,
    public_key: felt252
) -> felt252
```

### Requirements

* The return value of both functions is the same as `__validate__` (`'VALID'` or halted transaction).
* Both functions should only be callable by the Starknet protocol (same as `__validate__`).

### Verification

When completed, run the script below to verify your implementation.

```
$ scarb run verify_step5
```

### Hints

* Create a private function to encapsulate the logic of `__validate__` so it can be reused by `__validate_declare__` and `__validate_deploy__`.
* By grouping private functions into its own trait they can be called as methods of `self` and the smart contract state doesn’t need to be explicitly passed.
* You can auto generate a trait from an implementation using the attribute `generate_trait`.

## Step 6

If you fell behind, catch up to this step by running the command below.

```
$ git stash && git checkout -b step6 origin/step6
```

### Goal

Implement the function `__execute__` as defined by the [SNIP-6](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-6.md) standard.

### Requirements

* The function should be able to handle a single contract call or multiple contract calls in sequence.
* The result of each call should be collected and returned as an array.
* If an empty array of calls is passed, the function should halt and revert the transaction.
* The function should only be called by the protocol (the zero address).

### Verification

Starknet Foundry has a [bug](https://github.com/foundry-rs/starknet-foundry/issues/1079) that prevents creating a test for this step. Once the bug is fixed, this workshop will be updated with a verification test.

### Hints

* You can call other contracts using the low level syscall `call_contract_syscall` available in the `starknet` module.
* You can iterate over an array by using the `loop` keyword and the array method `pop_front`.

## Step 7

If you fell behind, catch up to this step by running the command below.

```
$ git stash && git checkout -b step7 origin/step7
```

### Goal

Implement the function `supports_interface` from the [SNIP-5](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-5.md) standard for the [SNIP-6](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-6.md) interface.

### Requirements

* When providing the `interface_id` of the SNIP-6 trait the function should return `true`.
* When providing any other value for `interface_id` the function should return `false`.

### Verification

When completed, run the script below to verify your implementation.

```
$ scarb run verify_step7
```

### Hints

* The `interface_id` of the SNIP-6 trait is `1270010605630597976495846281167968799381097569185364931397797212080166453709`

## Step 8

If you fell behind, catch up to this step by running the command below.

```
$ git stash && git checkout -b step8 origin/step8
```

### Goal

Limit execution of the functions `__execute__`, `__validate__`, `__validate_declare__` and `__validate_deploy__` to transactions of the [latest version](https://docs.starknet.io/documentation/architecture_and_concepts/Network_Architecture/transactions/).

### Requirements

* Attempting to execute an `invoke`, `declare`, and `deploy_account` transaction that is not of the latest version should result in the transaction being halted and reverted.
* Simulated transactions should be supported.

### Verification

When completed, run the script below to verify your implementation.

```
$ scarb run verify_step8
```

### Hints

* Simulated transactions use the same version as their real counterpart but offset by `2^128`.

## Step 9 (Final)

If you fell behind, catch up to this step by running the command below.

```
$ git stash && git checkout -b step9 origin/step9
```

### Goal

Check that you have correctly created an account contract for Starknet by running the full test suite:

```
$ scarb test
```

If the test suite passes, congratulations, you have created your first custom Starknet account contract thanks to account abstraction.

# Bonus: Deploying to Testnet

You can deploy your account contract to Starknet testnet in two ways, using [Starkli](https://github.com/xJonathanLEI/starkli) (CLI) or using [Starknet.js](https://www.starknetjs.com/) (SDK).

Using Starkli to deploy an account contract is a "manual" process but you can follow this [tutorial](https://medium.com/starknet-edu/account-abstraction-on-starknet-part-iii-698904e7792c) to learn how to do it. On the other hand, with an SDK like Starknet.js you can automate the process of declaring, deploying and testing an account contract.

The following bonus steps will show you how to configure and use the `deploy.ts` script found in the `scripts` folder to deploy your account contract to Starknet testnet.

## Dependencies

Install the dependencies required to run the deployer script.

### Steps

1. Install [Nodejs](https://nodejs.org/en/) 20 or higher on your computer. You can use [`asdf`](https://asdf-vm.com/) for that too.
1. Once you have Nodejs, install the script dependencies by running `npm install` from the project's root folder.

## Deployer Wallet

Create a wallet that the script can use to pay for the declaration of your account contract.

### Steps

1. Create a wallet on Starknet **testnet** using the [Argent X](https://www.argent.xyz/argent-x/) or [Braavos](https://braavos.app/) browser extension.
1. Fund the wallet by using the [Faucet](https://faucet.goerli.starknet.io/) or the [Bridge](https://goerli.starkgate.starknet.io/).
1. Create a file in the project's root folder called `.env`
1. Export the private key of the funded wallet and paste it in the `.env` file using the key `DEPLOYER_PRIVATE_KEY`.

```
DEPLOYER_PRIVATE_KEY=<YOUR_FUNDED_TESTNET_WALLET_PK>
```

## RPC Endpoint

Provide an RPC URL that the script can use to interact with Starknet testnet.

### Steps

1. Create an account on [Infura](https://www.infura.io/).
1. Create a new API Key for a Web3.
1. Copy the RPC URL for Starknet's testnet.
1. Paste the RPC URL in the `.env` file using the key `RPC_ENDPOINT`.

```
DEPLOYER_PRIVATE_KEY=<YOUR_FUNDED_TESTNET_WALLET_PK>
RPC_ENDPOINT=<YOUR_RPC_URL_FOR_STARKNET_TESTNET>
```

## Run the Script

Run the script that will declare, deploy and use your account contract to send a small amount of ETH to another wallet as a test.

### Steps

1. From project's root folder run `npm run deploy`
1. Follow the instructions from the terminal

If the script finishes successfully your account contract is ready to be used on Starknet testnet.