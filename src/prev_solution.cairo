#[starknet::interface]
trait IAccount<T> {
    fn public_key(self: @T) -> felt252;
    fn __execute__(self: @T);
    fn __validate__(self: @T);
}

#[starknet::contract(account)]
mod Account {
    use super::IAccount;

    #[storage]
    struct Storage {
        public_key: felt252
    }

    #[constructor]
    fn constructor(ref self: ContractState, public_key: felt252) {
        self.public_key.write(public_key);
    }

    #[abi(embed_v0)]
    impl AccountImpl of IAccount<ContractState> {
        fn public_key(self: @ContractState) -> felt252 {
            self.public_key.read()
        }
        fn __execute__(self: @ContractState){}
        fn __validate__(self: @ContractState){}
    }
}