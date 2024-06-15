#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use core::array::ArrayTrait;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};
    use starkgo::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::game
    };

    #[test]
    #[available_gas(30000000)]
    fn test_move() {
        // caller
        let _caller = starknet::contract_address_const::<0x0>();

        // models
        let mut models = array![game::TEST_CLASS_HASH];

        // deploy world with models
        let world = spawn_test_world(models);

        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let actions_system = IActionsDispatcher { contract_address };

        // call spawn()
        actions_system.create_game(1);

    }
}
