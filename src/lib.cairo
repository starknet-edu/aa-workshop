use array::{ArrayTrait, SpanTrait};
use starknet::account::Call;

trait IAccount<T> {
    fn __execute__(ref self: T, calls: Array<Call>) -> Array<Span<felt252>>;
    fn __validate__(self: @T, calls: Array<Call>) -> felt252;
    fn __validate_declare__(self: @T, class_hash: felt252) -> felt252;
    fn __validate_deploy__(self: @T, class_hash: felt252, salt: felt252, public_key: felt252) -> felt252;
    fn is_valid_signature(self: @T, hash: felt252, signature: Array<felt252>) -> felt252;
    fn supports_interface(self: @T, interface_id: felt252) -> bool;
    fn get_public_key(self: @T) -> felt252;
}

#[starknet::contract]
mod Account {

    use super::{ArrayTrait, SpanTrait, Call, IAccount};
    use box::BoxTrait;
    use ecdsa::check_ecdsa_signature;
    use zeroable::Zeroable;
    use starknet::account::AccountContract;
    use starknet::ContractAddress;
    use starknet::{get_tx_info, get_caller_address};

    const SUPPORTED_INVOKE_TX_VERSION: felt252 = 1;
    const SUPPORTED_DECLARE_TX_VERSION: felt252 = 2;
    const SUPPORTED_DEPLOY_ACCOUNT_TX_VERSION: felt252 = 1;
    const SIMULATE_TX_VERSION_OFFSET: felt252 = 340282366920938463463374607431768211456; // 2**128

    // hex: 0x2ceccef7f994940b3962a6c67e0ba4fcd37df7d131417c604f91e03caecc1cd
    const SRC6_TRAIT_ID: felt252 = 1270010605630597976495846281167968799381097569185364931397797212080166453709;

    #[storage]
    struct Storage {
        public_key: felt252
    }

    #[constructor]
    fn constructor(ref self: ContractState, public_key: felt252) {
        self.public_key.write(public_key);
    }

    #[external(v0)]
    impl PublicMethods of IAccount<ContractState> {

        fn __execute__(ref self: ContractState, calls: Array<Call>) -> Array<Span<felt252>> {
            self._only_protocol();
            self._only_supported_tx_version(SUPPORTED_INVOKE_TX_VERSION);
            self._execute_calls(calls)
        }

        fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
            self._only_protocol();
            self._only_supported_tx_version(SUPPORTED_INVOKE_TX_VERSION);
            self._validate_transaction()
        }

        fn __validate_declare__(self: @ContractState, class_hash: felt252) -> felt252 {
            self._only_protocol();
            self._only_supported_tx_version(SUPPORTED_DECLARE_TX_VERSION);
            self._validate_transaction()
        }

        fn __validate_deploy__(self: @ContractState, class_hash: felt252, salt: felt252, public_key: felt252) -> felt252 {
            self._only_protocol();
            self._only_supported_tx_version(SUPPORTED_DEPLOY_ACCOUNT_TX_VERSION);
            self._validate_transaction()
        }

        fn is_valid_signature(self: @ContractState, hash: felt252, signature: Array<felt252>) -> felt252 {
            let is_valid = self._is_valid_signature(hash, signature.span());
            if is_valid == true { starknet::VALIDATED } else { 0 }
        }

        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            interface_id == SRC6_TRAIT_ID
        }

        fn get_public_key(self: @ContractState) -> felt252 {
            self.public_key.read()
        }
    }

    #[generate_trait]
    impl PrivateMethods of PrivateTrait {

        fn _validate_transaction(self: @ContractState) -> felt252 {
            let tx_info = get_tx_info().unbox();
            let tx_hash = tx_info.transaction_hash;
            let signature = tx_info.signature;
            
            assert(self._is_valid_signature(tx_hash, signature), 'Account: invalid signature');
            starknet::VALIDATED
        }

        fn _is_valid_signature(self: @ContractState, hash: felt252, signature: Span<felt252>) -> bool {
            let is_valid_length = signature.len() == 2_u32;

            if !is_valid_length {
                return false;
            }
            
            check_ecdsa_signature(
                hash, self.public_key.read(), *signature.at(0_u32), *signature.at(1_u32)
            )
        }

        fn _execute_calls(self: @ContractState, mut calls: Array<Call>) -> Array<Span<felt252>> {
            let mut res = ArrayTrait::new();
            loop {
                match calls.pop_front() {
                    Option::Some(call) => {
                        let _res = self._execute_single_call(call);
                        res.append(_res);
                    },
                    Option::None(_) => {
                        break ();
                    },
                };
            };
            res
        }

        fn _execute_single_call(self: @ContractState, call: Call) -> Span<felt252> {
            let Call{to, selector, calldata } = call;
            starknet::call_contract_syscall(to, selector, calldata.span()).unwrap_syscall()
        }

        fn _only_supported_tx_version(self: @ContractState, supported_tx_version: felt252) {
            let tx_info = get_tx_info().unbox();
            let version = tx_info.version;
            assert(
                version == supported_tx_version ||
                version == SIMULATE_TX_VERSION_OFFSET + supported_tx_version,
                'Account: Unsupported tx version'
            );
        }

        fn _only_protocol(self: @ContractState) {
            let sender = get_caller_address();
            assert(sender.is_zero(), 'Account: invalid caller');
        }
    }
}