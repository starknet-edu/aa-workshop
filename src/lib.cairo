use snrc::ISRC6;

#[starknet::contract]
mod Account {

    use array::{ArrayTrait, SpanTrait};
    use starknet::account::{Call, AccountContract};
    use starknet::ContractAddress;
    use starknet::get_tx_info;
    use ecdsa::check_ecdsa_signature;
    use box::BoxTrait;
    use starknet::get_caller_address;
    use zeroable::Zeroable;

    const TRANSACTION_VERSION: felt252 = 1;
    // 2**128 + TRANSACTION_VERSION
    const QUERY_VERSION: felt252 = 340282366920938463463374607431768211457;

    #[storage]
    struct Storage {
        public_key: felt252
    }

    #[constructor]
    fn constructor(ref self: ContractState, public_key: felt252) {
        self.public_key.write(public_key);
    }

    #[external(v0)]
    impl ISRC6Impl of super::ISRC6<ContractState> {

        fn __validate__(
            ref self: ContractState,
            calls: Array<Call>
        ) -> felt252 {
            self.validate_transaction()
        }

        fn __execute__(ref self: ContractState, calls: Array<Call>) -> Array<Span<felt252>> {
            // Avoid calls from other contracts
            // https://github.com/OpenZeppelin/cairo-contracts/issues/344
            let sender = get_caller_address();
            assert(sender.is_zero(), 'Account: invalid caller');

            // Check tx version
            let tx_info = get_tx_info().unbox();
            let version = tx_info.version;
            if version != TRANSACTION_VERSION {
                assert(version == QUERY_VERSION, 'Account: invalid tx version');
            }

            self._execute_calls(calls)
        }

        fn is_valid_signature(self: @ContractState, hash: felt252, signature: Array<felt252>) -> felt252 {
            let is_valid = self._is_valid_signature(hash, signature.span());
            if is_valid == true { starknet::VALIDATED } else { 0 }
        }
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrat {
        fn validate_transaction(self: @ContractState) -> felt252 {
            let tx_info = get_tx_info().unbox();
            let tx_hash = tx_info.transaction_hash;
            let signature = tx_info.signature;
            assert(self._is_valid_signature(tx_hash, signature), 'Account: invalid signature');
            starknet::VALIDATED
        }

        fn _is_valid_signature(self: @ContractState, hash: felt252, signature: Span<felt252>) -> bool {
            let valid_length = signature.len() == 2_u32;

            if valid_length {
                check_ecdsa_signature(
                    hash, self.public_key.read(), *signature.at(0_u32), *signature.at(1_u32)
                )
            } else {
                false
            }
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
    }
}

