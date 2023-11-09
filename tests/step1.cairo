use aa::account::{ IAccountDispatcher, IAccountDispatcherTrait };

use super::utils::deploy_contract;

#[test]
fn check_stored_public_key() {
    let public_key = 999;
    let contract_address = deploy_contract(public_key);
    let dispatcher = IAccountDispatcher{ contract_address };
    let stored_public_key = dispatcher.public_key();
    assert(public_key == stored_public_key, 'Wrong publick key');
}