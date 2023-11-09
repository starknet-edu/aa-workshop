use aa::account::{ IAccountDispatcher, IAccountDispatcherTrait };

use super::utils::deploy_contract;

#[test]
fn supports_snip6_interface() {
    let public_key = 1234;
    let contract_address = deploy_contract(public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let snip6_interface_id = 1270010605630597976495846281167968799381097569185364931397797212080166453709;

    let is_supported = dispatcher.supports_interface(snip6_interface_id);
    assert(is_supported == true, 'SNIP6 not supported');
}

#[test]
fn supports_other_interface() {
    let public_key = 1234;
    let contract_address = deploy_contract(public_key);
    let dispatcher = IAccountDispatcher{ contract_address };

    let random_interface_id = 99999999;

    let is_supported = dispatcher.supports_interface(random_interface_id);
    assert(is_supported == false, 'Random interface supported');
}