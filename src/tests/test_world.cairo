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
        models::{
            game::{games, Prisoners, Games, GameState,}, 
            board::{Position, Row, Column, print_board}
        }
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
    #[available_gas(35000000)]
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

    #[test]
    #[available_gas(63000000)]
    fn test_start() {
        let game_id: felt252 = 1;        
        let controller = starknet::contract_address_const::<0x01>();

        let (world, actions_system) = setup_world(game_id);
        let opponent = starknet::contract_address_const::<0x2>();
        actions_system.create_game(game_id);
        set_contract_address(opponent);
        actions_system.join_game(game_id);
        set_contract_address(controller);
        actions_system.set_black(game_id, true);
        set_contract_address(opponent);
        actions_system.set_black(game_id, true);
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.state == GameState::Ongoing);
    }

    #[test]
    #[should_panic(expected: ("Move forbidden by ko rule", 0x454e545259504f494e545f4641494c4544))]
    #[available_gas(770000000)]
    // #[ignore]
    fn test_capture_and_ko() {
        let game_id: felt252 = 1;        
        let controller = starknet::contract_address_const::<0x01>();
        let (world, actions_system) = setup_world(game_id);
        let opponent = starknet::contract_address_const::<0x2>();
        actions_system.create_game(game_id);
        set_contract_address(opponent);
        actions_system.join_game(game_id);
        set_contract_address(controller);
        actions_system.set_black(game_id, true);
        set_contract_address(opponent);
        actions_system.set_black(game_id, true);

        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::D, y: Column::Five });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::D, y: Column::Six });
        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::E, y: Column::Six });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::E, y: Column::Five });
        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::D, y: Column::Seven });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::F, y: Column::Six });
        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::C, y: Column::Six });

        let current_game = get!(world, game_id, (Games));
        assert!(current_game.prisoners == Prisoners { black: 1, white: 0 });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::E, y: Column::Seven });
        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::E, y: Column::Four });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::D, y: Column::Six });
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.prisoners == Prisoners { black: 1, white: 1 });
        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::E, y: Column::Six });
    }

    #[test]
    #[available_gas(337000000)]
    // #[ignore]
    fn test_capture_multiple_groups() {
        let game_id: felt252 = 1;        
        let controller = starknet::contract_address_const::<0x01>();
        let (world, actions_system) = setup_world(game_id);
        let opponent = starknet::contract_address_const::<0x2>();
        
        actions_system.create_game(game_id);
        set_contract_address(opponent);
        actions_system.join_game(game_id);
        set_contract_address(controller);
        actions_system.set_black(game_id, true);
        set_contract_address(opponent);
        actions_system.set_black(game_id, true);

        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::A, y: Column::One });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::B, y: Column::One });
        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::A, y: Column::Three });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::B, y: Column::Three });
        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::B, y: Column::Two });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::C, y: Column::Two });
        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::C, y: Column::Three });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::A, y: Column::Four });
        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::D, y: Column::Two });
        set_contract_address(opponent);
        actions_system.play_move(game_id, Position { x: Row::A, y: Column::Two });
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.prisoners == Prisoners { black: 0, white: 3 });
    }

    #[test]
    #[available_gas(133000000)]
    // #[ignore]
    fn test_pass_to_finish() {
        let game_id: felt252 = 1;        
        let controller = starknet::contract_address_const::<0x01>();
        let (world, actions_system) = setup_world(game_id);
        let opponent = starknet::contract_address_const::<0x2>();
        actions_system.create_game(game_id);
        set_contract_address(opponent);
        actions_system.join_game(game_id);
        set_contract_address(controller);
        actions_system.set_black(game_id, true);
        set_contract_address(opponent);
        actions_system.set_black(game_id, true);

        set_contract_address(controller);
        actions_system.play_move(game_id, Position { x: Row::C, y: Column::Three });

        let current_game = get!(world, game_id, (Games));
        assert!(current_game.last_passed == false, "No one passed yet.");
        assert!(current_game.nb_moves == 1, "Should be one move.");
        set_contract_address(opponent);
        actions_system.pass(game_id);
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.state == GameState::Ongoing, "Should still be 'Ongoing'.");
        assert!(current_game.last_passed == true, "Pass not registered.");
        assert!(current_game.nb_moves == 2, "Should be two moves.");
        set_contract_address(controller);
        actions_system.pass(game_id);
        assert!(current_game.last_passed == true, "Other not registered.");
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.nb_moves == 3, "Should be three moves.");
        assert!(current_game.state == GameState::Finished);
    }
}
