# Starknet Smart Wallet Workshop

## Install  asdf

[Official Docs](https://asdf-vm.com/guide/getting-started.html)

Download `asdf`

```
$ git clone https://github.com/asdf-vm/asdf.git ~/.asdf
```

Activate `asdf` plugin for `oh-my-zsh` in `.zshrc`

```bash
$ code ~/.zshrc
```

```zsh
# ~/.zshrc
...
plugins=(git asdf)
...
```

Restart the terminal

Check if `asdf` is enabled

```
$ asdf --version
v0.12.0-d1a563d
```

## Install Scarb

[Official docs](https://docs.swmansion.com/scarb/download#install-via-asdf)

Add `scarb` plugin to `asdf`

```
$ asdf plugin add scarb https://github.com/software-mansion/asdf-scarb.git
```

Install scarb 0.5.1 globally

```
$ asdf install scarb 0.5.1
```

Set up version 0.5.1 globally

```
$ asdf global scarb 0.5.1
```

Verify that `scarb` is available globally

```
$ scarb --version
```

## Create project

Create a project with scarb

```
$ scarb new aa
$ cd aa
```

Modify `Scarb.toml` to support Starknet

```toml
...

[dependencies]
starknet = "2.0.1"

[cairo]
sierra-replace-ids = true

[[target.starknet-contract]]
sierra = true
```

Install Cairo 1 extension in vscode

Create minimal account contract
`src/lib.cairo`

```rust
#[starknet::contract]
mod Account {
    #[storage]
    struct Storage {}
}
```

Verify that it compiles

```
$ scarb build
```

## Create empty interface

Create empty `IAccount` trait for public methods

```rust
trait IAccount<T> {}

#[starknet::contract]
mod Account {
  use super::IAccount;
  ...
  #[external(v0)]
  impl PublicMethods of IAccount<ContractState> {}
}
```

Verify that it compiles

```
$ scarb build
```

## Implement `__validate__` placeholder

Create trait with single function

```rust
use array::ArrayTrait;
use starknet::account::Call;

trait IAccount<T> {
    fn __validate__(self: @T, calls: Array<Call>) -> felt252;
}

#[starknet::contract]
mod Account { 
  ...
}
```

Implement trait as `external`

```rust
...

#[starknet::contract]
mod Account { 
  use super::{ArrayTrait, Call, IAccount};
  use starknet::VALIDATED;
  
  #[storage]
  struct Storage {}

  #[external(v0)]
  impl PublicMethods of IAccount<ContractState> {

    fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
      VALIDATED
    }
  }
}
```

Verify that it compiles

```
$ scarb build
```

## Capture public key

Pass the public key to the constructor and store it

```rust
...

#[starknet::contract]
mod Account { 
  ...
  
  #[storage]
  struct Storage {
    public_key: felt252
  }

  #[constructor]
  fn constructor(ref self: ContractState, public_key: felt252) {
    self.public_key.write(public_key);
  }
  ...
}
```

## Verify signature

Extract data from tx

```rust
...

#[starknet::contract]
mod Account { 
  use starknet::{VALIDATED, get_tx_info};
  use box::BoxTrait;
  ...

  #[external(v0)]
  impl PublicMethods of IAccount<ContractState> {
  
    fn __validate__(...) -> felt252 {
      let tx_info = get_tx_info().unbox();
      let tx_hash = tx_info.transaction_hash;
      let signature = tx_info.signature;
      VALIDATED
    }
  }
}
```

Verify signature

```rust
...

#[starknet::contract]
mod Account { 
  use array::SpanTrait;
  use ecdsa::check_ecdsa_signature;
  ...

  #[external(v0)]
  impl PublicMethods of IAccount<ContractState> {
  
    fn __validate__(...) -> felt252 {
      ...

      let is_valid_length = signature.len() == 2_u32;

      if !is_valid_length {
          return 0;
      }

      let is_valid_signature = check_ecdsa_signature(
        tx_hash,
        self.public_key.read(),
        *signature.at(0_u32),
        *signature.at(1_u32)
      );

      assert(is_valid_signature, 'Account: Invalid signature');
      VALIDATED
    }
  }
}
```

## Refactor `_is_valid_signature`

Create private methods

```rust
...

#[starknet::contract]
mod Account { 
  ...

  #[generate_trait]
  impl PrivateMethods of PrivateTrait {

    fn _is_valid_signature(
      self: @ContractState,
      hash: felt252,
      signature: Span<felt252>
    )-> bool {

      let is_valid_length = signature.len() == 2_u32;

      if !is_valid_length {
        return false;
      }
            
      check_ecdsa_signature(
        hash,
        self.public_key.read(),
        *signature.at(0_u32),
        *signature.at(1_u32)
      )
    }
  }
}
```

Use private function
```rust
...

#[starknet::contract]
mod Account {
  ...

  #[external(v0)]
  impl PublicMethods of IAccount<ContractState> {

    fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
      ...

      let is_valid = self._is_valid_signature(
        tx_hash,
        signature
      );

      assert(is_valid, 'Account: Invalid signature');
      VALIDATED
    }
  }

  #[generate_trait]
  impl PrivateMethods of PrivateTrait { ... }
}
```

## Implement other validations

Move validation logic to private function

```rust
...

#[starknet::contract]
mod Account {
  ...

  #[external(v0)]
  impl PublicMethods of super::IAccount<ContractState> {
    fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
      self._validate_transaction()
    }
  }

  #[generate_trait]
  impl PrivateMethods of PrivateTrait {
      
    fn _validate_transaction(self: @ContractState) -> felt252 {
      let tx_info = get_tx_info().unbox();
      let tx_hash = tx_info.transaction_hash;
      let signature = tx_info.signature;

      let is_valid = self._is_valid_signature(
        tx_hash,
        signature
      );

      assert(is_valid, 'Account: Invalid signature');
      VALIDATED
    }
    ...
  }
}
```

Add new validation functions to interface

```rust
...

trait IAccount<T> {
  fn __validate__(self: @T, calls: Array<Call>) -> felt252;
  fn __validate_declare__(self: @T, class_hash: felt252) -> felt252;
  fn __validate_deploy__(self: @T, class_hash: felt252, salt: felt252, public_key: felt252) -> felt252;
}

#[starknet::contract]
mod Account {
  ...
}
```

Implement new validation functions

```rust
...

#[starknet::contract]
mod Account {
  ...

  #[external(v0)]
  impl PublicMethods of IAccount<ContractState> {
    fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
      self._validate_transaction()
    }

    fn __validate_declare__(self: @ContractState, class_hash: felt252) -> felt252 {
      self._validate_transaction()
    }

    fn __validate_deploy__(self: @ContractState, class_hash: felt252, salt: felt252, public_key: felt252) -> felt252 {
      self._validate_transaction()
    }
  }
  ...
}
```

## Implement `is_valid_signature`

Used by dapps to check signature without tx

```rust
...
trait IAccount<T> {
  ...
  fn is_valid_signature(self: @T, hash: felt252, signature: Array<felt252>) -> felt252;
}

#[starknet::contract]
mod Account {
  ...
  #[external(v0)]
  impl PublicMethods of IAccount<ContractState> {
    ...
    fn is_valid_signature(self: @ContractState, hash: felt252, signature: Array<felt252>) -> felt252 {
      let is_valid = self._is_valid_signature(hash, signature.span());
      if is_valid == true { starknet::VALIDATED } else { 0 }
    }
  }
  ...
}
```