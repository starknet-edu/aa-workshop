#[starknet::interface]
trait IAccount<T> {
    fn __execute__(self: @T);
    fn __validate__(self: @T);
}

#[starknet::contract(account)]
mod Account {
    use super::IAccount;

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl AccountImpl of IAccount<ContractState> {
        fn __execute__(self: @ContractState){}
        fn __validate__(self: @ContractState){}
    }
}