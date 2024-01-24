use starknet::{ ContractAddress, account::Call };
use aa::account::{ IAccountDispatcher, IAccountDispatcherTrait, SUPPORTED_TX_VERSION };
use snforge_std::signature::StarkCurveKeyPairTrait;
use snforge_std::{ start_prank, stop_prank, start_spoof, stop_spoof, CheatTarget };
use super::utils::{ deploy_contract, create_tx_info_mock };

const SIMULATE_TX_VERSION_OFFSET: felt252 = 340282366920938463463374607431768211456; // 2**128

#[test]
fn supported_real_declare_tx() {
    let mut signer = StarkCurveKeyPairTrait::from_private_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let tx_hash_mock = 123;
    let tx_version_mock = SUPPORTED_TX_VERSION::DECLARE;
    let tx_info_mock = create_tx_info_mock(tx_hash_mock, ref signer, tx_version_mock);

    let class_hash_mock = 999;
    let zero_address: ContractAddress = 0.try_into().unwrap();

    start_prank(CheatTarget::One(contract_address), zero_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    dispatcher.__validate_declare__(class_hash_mock);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
fn supported_simulated_declare_tx() {
    let mut signer = StarkCurveKeyPairTrait::from_private_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let tx_hash_mock = 123;
    let tx_version_mock = SUPPORTED_TX_VERSION::DECLARE + SIMULATE_TX_VERSION_OFFSET;
    let tx_info_mock = create_tx_info_mock(tx_hash_mock, ref signer, tx_version_mock);

    let class_hash_mock = 999;
    let zero_address: ContractAddress = 0.try_into().unwrap();

    start_prank(CheatTarget::One(contract_address), zero_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    dispatcher.__validate_declare__(class_hash_mock);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
#[should_panic]
fn unsupported_declare_tx() {
    let mut signer = StarkCurveKeyPairTrait::from_private_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let tx_hash_mock = 123;
    let tx_version_mock = 1;
    let tx_info_mock = create_tx_info_mock(tx_hash_mock, ref signer, tx_version_mock);

    let class_hash_mock = 999;
    let zero_address: ContractAddress = 0.try_into().unwrap();

    start_prank(CheatTarget::One(contract_address), zero_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    dispatcher.__validate_declare__(class_hash_mock);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
fn supported_real_declare_deploy_tx() {
    let mut signer = StarkCurveKeyPairTrait::from_private_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let tx_hash_mock = 123;
    let tx_version_mock = SUPPORTED_TX_VERSION::DEPLOY_ACCOUNT;
    let tx_info_mock = create_tx_info_mock(tx_hash_mock, ref signer, tx_version_mock);

    let class_hash_mock = 999;
    let salt_mock = 1;
    let zero_address: ContractAddress = 0.try_into().unwrap();

    start_prank(CheatTarget::One(contract_address), zero_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    dispatcher.__validate_deploy__(class_hash_mock, salt_mock, signer.public_key);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
fn supported_simulated_declare_deploy_tx() {
    let mut signer = StarkCurveKeyPairTrait::from_private_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let tx_hash_mock = 123;
    let tx_version_mock = SUPPORTED_TX_VERSION::DEPLOY_ACCOUNT + SIMULATE_TX_VERSION_OFFSET;
    let tx_info_mock = create_tx_info_mock(tx_hash_mock, ref signer, tx_version_mock);

    let class_hash_mock = 999;
    let salt_mock = 1;
    let zero_address: ContractAddress = 0.try_into().unwrap();

    start_prank(CheatTarget::One(contract_address), zero_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    dispatcher.__validate_deploy__(class_hash_mock, salt_mock, signer.public_key);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
#[should_panic]
fn unsupported_declare_deploy_tx() {
    let mut signer = StarkCurveKeyPairTrait::from_private_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let tx_hash_mock = 123;
    let tx_version_mock = 0;
    let tx_info_mock = create_tx_info_mock(tx_hash_mock, ref signer, tx_version_mock);

    let class_hash_mock = 999;
    let salt_mock = 1;
    let zero_address: ContractAddress = 0.try_into().unwrap();

    start_prank(CheatTarget::One(contract_address), zero_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    dispatcher.__validate_deploy__(class_hash_mock, salt_mock, signer.public_key);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));
}