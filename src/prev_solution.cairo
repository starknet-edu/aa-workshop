use starknet::account::Call;

#[starknet::interface]
trait IAccount<T> {
    fn public_key(self: @T) -> felt252;
    fn is_valid_signature(self: @T, hash: felt252, signature: Array<felt252>) -> felt252;
    fn __validate__(self: @T, calls: Array<Call>) -> felt252;
}

#[starknet::contract]
mod Account {
    use super::{Call, IAccount};
    use starknet::{get_caller_address, get_tx_info, VALIDATED};
    use zeroable::Zeroable;
    use ecdsa::check_ecdsa_signature;

    #[storage]
    struct Storage {
        public_key: felt252
    }

    #[constructor]
    fn constructor(ref self: ContractState, public_key: felt252) {
        self.public_key.write(public_key);
    }

    #[external(v0)]
    impl AccountImpl of IAccount<ContractState> {
        fn public_key(self: @ContractState) -> felt252 {
            self.public_key.read()
        }

        fn is_valid_signature(self: @ContractState, hash: felt252, signature: Array<felt252>) -> felt252 {
            let is_valid = self.is_valid_signature_bool(hash, signature.span());
            if is_valid { VALIDATED } else { 0 }
        }
        
        fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
            let sender = get_caller_address();
            assert(sender.is_zero(), 'Account: invalid caller');

            let tx_info = get_tx_info().unbox();
            let tx_hash = tx_info.transaction_hash;
            let signature = tx_info.signature;
            
            let is_valid = self.is_valid_signature_bool(tx_hash, signature);
            assert(is_valid, 'Account: Incorrect tx signature');
            VALIDATED
        }
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn is_valid_signature_bool(self: @ContractState, hash: felt252, signature: Span<felt252>) -> bool {
            let is_valid_length = signature.len() == 2_u32;
            if !is_valid_length {
                return false;
            }
            check_ecdsa_signature(
                hash, self.public_key.read(), *signature.at(0_u32), *signature.at(1_u32)
            )
        }    
    }
}