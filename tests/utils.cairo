use starknet::{ ContractAddress, account::Call };
use snforge_std::{ 
    declare,
    cheatcodes::contract_class::ContractClassTrait
};
// use snforge_std::signature::{ interface::Signer, StarkCurveKeyPair };
use snforge_std::{ TxInfoMock, TxInfoMockTrait };
use snforge_std::signature::{KeyPairTrait, KeyPair};
use snforge_std::signature::stark_curve::{StarkCurveKeyPairImpl, StarkCurveSignerImpl, StarkCurveVerifierImpl};


fn deploy_contract(public_key: felt252) -> ContractAddress {
    let contract = declare('Account');
    let constructor_args = array![public_key];
    return contract.deploy(@constructor_args).unwrap();
}

fn create_call_array_mock() -> Array<Call> {
    let call = Call {
        to: 111.try_into().unwrap(),
        selector: 'fake_endpoint',
        calldata: array![],
    };
    return array![call];
}

fn create_tx_info_mock(tx_hash: felt252, ref signer: KeyPair<felt252, felt252>, tx_version: felt252) -> TxInfoMock {
    let (r, s): (felt252, felt252) = signer.sign(tx_hash);
    let tx_signature = array![r, s];

    let mut tx_info = TxInfoMockTrait::default();
    tx_info.transaction_hash = Option::Some(tx_hash);
    tx_info.signature = Option::Some(tx_signature.span());
    tx_info.version = Option::Some(tx_version);

    return tx_info;
}

mod SUPPORTED_TX_VERSION {
    const DEPLOY_ACCOUNT: felt252 = 1;
    const DECLARE: felt252 = 2;
    const INVOKE: felt252 = 1;
}