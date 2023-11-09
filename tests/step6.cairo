use starknet::{ ContractAddress, account::Call };
use aa::{ IAccountDispatcher, IAccountDispatcherTrait, SUPPORTED_TX_VERSION };
use snforge_std::{
    start_prank,
    stop_prank,
    start_mock_call,
    stop_mock_call,
    start_spoof,
    stop_spoof,
};
use snforge_std::{ TxInfoMock, TxInfoMockTrait };
use super::utils::{ deploy_contract, create_tx_info_mock };

#[test]
fn handles_a_single_call() {
    let contract_address = deploy_contract(123);
    let dispatcher = IAccountDispatcher{ contract_address };

    let call_address: ContractAddress = 'ramdom'.try_into().unwrap();
    let call_function = 'my_function';

    let call = Call {
        to: call_address,
        selector: call_function,
        calldata: array![],
    };

    let zero_address: ContractAddress = 0.try_into().unwrap();
    let ret_data_mock = 421;

    let mut tx_info_mock = TxInfoMockTrait::default();
    tx_info_mock.version = Option::Some(SUPPORTED_TX_VERSION::INVOKE);
    
    start_prank(contract_address, zero_address);
    start_spoof(contract_address, tx_info_mock);
    start_mock_call(call_address, call_function, ret_data_mock);
    let result = dispatcher.__execute__(array![call]);
    stop_mock_call(call_address, call_function);
    stop_spoof(contract_address);
    stop_prank(contract_address);
}

#[test]
fn handles_multiple_calls() {
    
}

#[test]
#[should_panic]
fn fails_on_empty_calls_array() {
    
}