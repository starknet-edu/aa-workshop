use core::array::ArrayTrait;
use starknet::{ ContractAddress, account::Call };
use aa::account::{ IAccountDispatcher, IAccountDispatcherTrait };
use snforge_std::{
    start_prank,
    stop_prank,
    start_mock_call,
    stop_mock_call,
    start_spoof,
    stop_spoof,
    CheatTarget,
};
use snforge_std::{ TxInfoMock, TxInfoMockTrait };
use super::utils::{ deploy_contract, create_tx_info_mock, SUPPORTED_TX_VERSION };

#[test]
fn handles_a_single_call() {
    let contract_address = deploy_contract(123);
    let dispatcher = IAccountDispatcher{ contract_address };

    let call_address: ContractAddress = 'ramdom'.try_into().unwrap();
    let call_function = 'my_function';

    let call = Call {
        to: call_address,
        selector: selector!("my_function"),
        calldata: array![],
    };

    let zero_address: ContractAddress = 0.try_into().unwrap();
    let ret_data_mock = 421;

    let mut tx_info_mock = TxInfoMockTrait::default();
    tx_info_mock.version = Option::Some(SUPPORTED_TX_VERSION::INVOKE);
    
    start_prank(CheatTarget::One(contract_address), zero_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    start_mock_call(call_address, call_function, ret_data_mock);
    let result = dispatcher.__execute__(array![call]);
    stop_mock_call(call_address, call_function);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));

    let unwrapped_result = *(*result.at(0)).at(0);

    assert(unwrapped_result == ret_data_mock, 'Wrong returned value');
}

#[test]
fn handles_multiple_calls() {
    let contract_address = deploy_contract(123);
    let dispatcher = IAccountDispatcher{ contract_address };

    let call_address_1: ContractAddress = 'ramdom_1'.try_into().unwrap();
    let call_function_1 = 'my_function_1';
    let call_1 = Call {
        to: call_address_1,
        selector: selector!("my_function_1"),
        calldata: array![],
    };
    let ret_data_mock_1 = 111;

    let call_address_2: ContractAddress = 'ramdom_2'.try_into().unwrap();
    let call_function_2 = 'my_function_2';
    let call_2 = Call {
        to: call_address_2,
        selector: selector!("my_function_2"),
        calldata: array![],
    };
    let ret_data_mock_2 = 222;

    let zero_address: ContractAddress = 0.try_into().unwrap();

    let mut tx_info_mock = TxInfoMockTrait::default();
    tx_info_mock.version = Option::Some(SUPPORTED_TX_VERSION::INVOKE);
    
    start_prank(CheatTarget::One(contract_address), zero_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    start_mock_call(call_address_1, call_function_1, ret_data_mock_1);
    start_mock_call(call_address_2, call_function_2, ret_data_mock_2);
    let result = dispatcher.__execute__(array![call_1, call_2]);
    stop_mock_call(call_address_2, call_function_2);
    stop_mock_call(call_address_1, call_function_1);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));

    let expected_result = array![array![ret_data_mock_1].span(), array![ret_data_mock_2].span()];
    assert(result == expected_result, 'Wrong returned values');
}

#[test]
#[should_panic]
fn fails_on_empty_calls_array() {
    let contract_address = deploy_contract(123);
    let dispatcher = IAccountDispatcher{ contract_address };
    dispatcher.__execute__(array![]);
}