use starknet::{ ContractAddress, account::Call };
use aa::account::{ IAccountDispatcher, IAccountDispatcherTrait };
// use snforge_std::signature::StarkCurveKeyPairTrait;
use snforge_std::signature::KeyPairTrait;
use snforge_std::signature::stark_curve::{StarkCurveKeyPairImpl, StarkCurveSignerImpl, StarkCurveVerifierImpl};
use snforge_std::{ start_prank, stop_prank, start_spoof, stop_spoof, CheatTarget };
use super::utils::{ deploy_contract, create_tx_info_mock, SUPPORTED_TX_VERSION };

#[test]
fn validate_declare_by_protocol_succeeds() {
    let mut signer = KeyPairTrait::from_secret_key(123);
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
#[should_panic]
fn validate_declare_by_non_protocol_fails() {
    let mut signer = KeyPairTrait::<felt252, felt252>::from_secret_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let tx_hash_mock = 123;
    let tx_version_mock = SUPPORTED_TX_VERSION::DECLARE;
    let tx_info_mock = create_tx_info_mock(tx_hash_mock, ref signer, tx_version_mock);

    let class_hash_mock = 999;
    let random_address: ContractAddress = 321.try_into().unwrap();

    start_prank(CheatTarget::One(contract_address), random_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    dispatcher.__validate_declare__(class_hash_mock);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
fn validate_deploy_by_protocol_succeeds() {
    let mut signer = KeyPairTrait::<felt252, felt252>::from_secret_key(123);
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
#[should_panic]
fn validate_deploy_by_non_protocol_fails() {
    let mut signer = KeyPairTrait::<felt252, felt252>::from_secret_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let tx_hash_mock = 123;
    let tx_version_mock = SUPPORTED_TX_VERSION::DEPLOY_ACCOUNT;
    let tx_info_mock = create_tx_info_mock(tx_hash_mock, ref signer, tx_version_mock);

    let class_hash_mock = 999;
    let salt_mock = 1;
    let random_address: ContractAddress = 321.try_into().unwrap();

    start_prank(CheatTarget::One(contract_address), random_address);
    start_spoof(CheatTarget::One(contract_address), tx_info_mock);
    dispatcher.__validate_deploy__(class_hash_mock, salt_mock, signer.public_key);
    stop_spoof(CheatTarget::One(contract_address));
    stop_prank(CheatTarget::One(contract_address));
}

