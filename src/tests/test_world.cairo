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
    #[available_gas(19800000)]
    fn test_create() {
        let game_id: felt252 = 1;        

        let (world, actions_system) = setup_world(game_id);
        actions_system.create_game(game_id);
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.state == GameState::Created);
    }

    #[test]
    #[available_gas(31900000)]
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
    #[available_gas(57000000)]
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
    #[available_gas(457000000)]
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
        actions_system.play_move(game_id, x: Row::D.into(), y: Column::Five.into());
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::D.into(), y: Column::Six.into());
        set_contract_address(controller);
        actions_system.play_move(game_id, x: Row::E.into(), y: Column::Six.into());
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::E.into(), y: Column::Five.into());
        set_contract_address(controller);
        actions_system.play_move(game_id, x: Row::D.into(), y: Column::Seven.into());
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::F.into(), y: Column::Six.into());
        set_contract_address(controller);
        actions_system.play_move(game_id, x: Row::C.into(), y: Column::Six.into());

        let current_game = get!(world, game_id, (Games));
        assert!(current_game.prisoners == Prisoners { black: 1, white: 0 });
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::E.into(), y: Column::Seven.into());
        set_contract_address(controller);
        actions_system.play_move(game_id, x: Row::E.into(), y: Column::Four.into());
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::D.into(), y: Column::Six.into());
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.prisoners == Prisoners { black: 1, white: 1 });
        set_contract_address(controller);
        actions_system.play_move(game_id, x: Row::E.into(), y: Column::Six.into());
    }

    #[test]
    #[available_gas(253000000)]
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
        actions_system.play_move(game_id, x: Row::A.into(), y: Column::One.into());
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::B.into(), y: Column::One.into());
        set_contract_address(controller);
        actions_system.play_move(game_id, x: Row::A.into(), y: Column::Three.into());
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::B.into(), y: Column::Three.into());
        set_contract_address(controller);
        actions_system.play_move(game_id, x: Row::B.into(), y: Column::Two.into());
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::C.into(), y: Column::Two.into());
        set_contract_address(controller);
        actions_system.play_move(game_id, x: Row::C.into(), y: Column::Three.into());
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::A.into(), y: Column::Four.into());
        set_contract_address(controller);
        actions_system.play_move(game_id, x: Row::D.into(), y: Column::Two.into());
        set_contract_address(opponent);
        actions_system.play_move(game_id, x: Row::A.into(), y: Column::Two.into());
        let current_game = get!(world, game_id, (Games));
        assert!(current_game.prisoners == Prisoners { black: 0, white: 3 });
    }

    #[test]
    #[available_gas(116000000)]
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
        actions_system.play_move(game_id, x: Row::C.into(), y: Column::Three.into());

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
