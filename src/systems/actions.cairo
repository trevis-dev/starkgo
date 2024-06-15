use starkgo::models::game::{Games, GameState};
use starkgo::models::board::{Board, Player, Position};
use starkgo::systems::move::Move;

#[dojo::interface]
trait IActions {
    fn create_game(ref world: IWorldDispatcher, game_id: felt252) -> felt252;
    fn join_game(ref world: IWorldDispatcher, game_id: felt252) -> bool;
    fn move(ref world: IWorldDispatcher, game_id: felt252, move: Move);
}

#[dojo::contract]
mod actions {
    use super::{IActions, GameState, Games, Move, Player, Position};
    use starknet::{ContractAddress, get_caller_address};

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_game(ref world: IWorldDispatcher, game_id: felt252) -> felt252 {
            let playerAddress = get_caller_address();
            let game = get!(world, game_id, (Games));
            match game.state {
                GameState::Inexistent => {
                    set!(
                        world,
                        (
                            Games {
                                game_id,
                                state: GameState::Created,
                                controller: Option::Some(playerAddress),
                                opponent: Option::None,
                                controller_has_black: false,
                                board: 0,
                                new_turn_player: Player::None,
                            }
                        )
                    );
                },
                _ => {
                    panic_with_felt252('game_id already used');
                }
            };
            game_id
        }

        fn join_game(ref world: IWorldDispatcher, game_id: felt252) -> bool {
            let playerAddress = get_caller_address();
            let game = get!(world, game_id, (Games));
            let mut newly_joined = false;
            match game.state {
                GameState::Inexistent => {
                    panic_with_felt252('Game does not exist');
                },
                GameState::Created => {
                    match (game.controller, game.opponent) {
                        (Option::None, _) => {
                            panic_with_felt252('Unexpected uncontrolled game');
                        },
                        (_, Option::Some(opponent)) => {
                            panic_with_felt252('Unexpected Created game state');
                        },
                        (Option::Some(controller), _) => {
                            if controller != playerAddress {
                                set!(
                                    world,
                                    (
                                        Games {
                                            game_id,
                                            state: GameState::Joined,
                                            controller: game.controller,
                                            opponent: Option::Some(playerAddress),
                                            controller_has_black: game.controller_has_black,
                                            board: game.board,
                                            new_turn_player: game.new_turn_player,
                                        }
                                    )
                                );
                                newly_joined = true;    
                            };
                        }
                    };
                },
                GameState::Joined => {
                    match (game.controller, game.opponent) {
                        (Option::Some(controller), Option::Some(opponent)) => {
                            if controller != playerAddress && opponent != playerAddress {
                                panic_with_felt252('Game can no longer be joined');
                            } // else don't panic, all good, just already joined.
                        },
                        (_, _) => {
                            panic_with_felt252('Unexpected Joined game state');
                        }
                    }
                },
                _ => {
                    panic_with_felt252('Game can no longer be joined');
                }
            };
            newly_joined
        }

        // Implementation of the move function for the ContractState struct.
        fn move(ref world: IWorldDispatcher, game_id: felt252, move: Move) {
            // Get the address of the current caller, possibly the player's address.
            let _player = get_caller_address();

            // Retrieve the player's current position and moves data from the world.
            // let (mut position, mut moves) = get!(world, player, (Position, Moves));

            // Deduct one from the player's remaining moves.
            // moves.remaining -= 1;

            // Update the last direction the player moved in.
            // moves.last_direction = direction;

            // Calculate the player's next position based on the provided direction.

            // Update the world state with the new moves data and position.
            // set!(world, (moves, next));
        // Emit an event to the world to notify about the player's move.
        // emit!(world, (moves));
        }
    }
}
