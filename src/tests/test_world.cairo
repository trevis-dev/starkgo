#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::ContractAddress;
    use starknet::testing::set_contract_address;
    use core::array::ArrayTrait;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};
    use starkgo::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::game::{Games, GameState, games}
    };

    fn setup_world(game_id: felt252) -> (IWorldDispatcher, IActionsDispatcher) {
        let caller = starknet::contract_address_const::<0x01>();
        set_contract_address(caller);

        // // models
        let mut models = array![games::TEST_CLASS_HASH];

        // // deploy world with models
        let world = spawn_test_world(models);

        // // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let actions_system = IActionsDispatcher { contract_address: contract_address };
        (world, actions_system)
    }

    #[test]
    #[available_gas(30000000)]
    fn test_create() {
        let game_id: felt252 = 1;        

        let (world, actions_system) = setup_world(game_id);
        actions_system.create_game(game_id);
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.state == GameState::Created);
    }

    #[test]
    #[available_gas(34000000)]
    fn test_join() {
        let game_id: felt252 = 1;        

        let (world, actions_system) = setup_world(game_id);
        let opponent = starknet::contract_address_const::<0x2>();
        actions_system.create_game(game_id);
        set_contract_address(opponent);
        actions_system.join_game(game_id);
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.state == GameState::Joined);
    }
}