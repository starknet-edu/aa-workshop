use core::option::OptionTrait;
use snforge_std::signature::{ interface::Signer, StarkCurveKeyPairTrait };
use aa::{ IAccountDispatcher, IAccountDispatcherTrait };
use starknet::VALIDATED;

use super::utils::deploy_contract;

#[test]
fn approve_valid_signature() {
    let mut signer = StarkCurveKeyPairTrait::from_private_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let message_hash = 456;
    let (r, s) = signer.sign(message_hash).unwrap();
    let signature = array![r, s];

    let validation = dispatcher.is_valid_signature(message_hash, signature);
    assert(validation == VALIDATED, 'Invalid signature');
}

#[test]
fn reject_invalid_signature() {
    let mut signer = StarkCurveKeyPairTrait::from_private_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let mut hacker = StarkCurveKeyPairTrait::from_private_key(456);
    let message_hash = 456;
    let (r, s) = hacker.sign(message_hash).unwrap();
    let signature = array![r, s];

    let validation = dispatcher.is_valid_signature(message_hash, signature);
    assert(validation != VALIDATED, 'Invalid signature accepted');
}