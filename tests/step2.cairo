use core::option::OptionTrait;
use snforge_std::signature::{KeyPairTrait};
use snforge_std::signature::stark_curve::{StarkCurveKeyPairImpl, StarkCurveSignerImpl, StarkCurveVerifierImpl};
use aa::account::{ IAccountDispatcher, IAccountDispatcherTrait };
use starknet::VALIDATED;

use super::utils::deploy_contract;

#[test]
fn approve_valid_signature() {
    let mut signer = KeyPairTrait::<felt252, felt252>::from_secret_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let message_hash = 456;
    let (r, s): (felt252, felt252) = signer.sign(message_hash);
    let signature = array![r, s];

    let validation = dispatcher.is_valid_signature(message_hash, signature);
    assert(validation == VALIDATED, 'Invalid signature');
}

#[test]
fn reject_invalid_signature() {
    let mut signer = KeyPairTrait::<felt252, felt252>::from_secret_key(123);
    let contract_address = deploy_contract(signer.public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let mut hacker = KeyPairTrait::<felt252, felt252>::from_secret_key(456);
    let message_hash = 456;
    let (r, s): (felt252, felt252) = hacker.sign(message_hash);
    let signature = array![r, s];

    let validation = dispatcher.is_valid_signature(message_hash, signature);
    assert(validation != VALIDATED, 'Invalid signature accepted');
}