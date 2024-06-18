
use starkgo::models::board::{Position};

#[dojo::interface]
trait IActions {
    fn create_game(ref world: IWorldDispatcher, game_id: felt252);
    fn join_game(ref world: IWorldDispatcher, game_id: felt252) -> bool;
    fn set_black(ref world: IWorldDispatcher, game_id: felt252, is_controller: bool);
    fn play_move(ref world: IWorldDispatcher, game_id: felt252, position: Position);
}

#[dojo::contract]
mod actions {
    use super::{ IActions };
    use starkgo::models::game::{ Prisoners, Games, GameState, GameResult, StartVote, applyMove};
    use starkgo::models::board::{ Board, Player, Position};
    use starknet::{ ContractAddress, get_caller_address };

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Moved: Moved,
    }
    #[derive(Drop, Serde, starknet::Event)]
    struct Moved {
        #[key]
        game_id: felt252,
        move_nb: u32,
        player: Player,
        position: Position
    }    

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_game(ref world: IWorldDispatcher, game_id: felt252) {
            let player_address = get_caller_address();
            let game = get!(world, game_id, (Games));
            match game.state {
                GameState::Inexistent => {
                    set!(
                        world,
                        (
                            Games {
                                game_id,
                                state: GameState::Created,
                                controller: Option::Some(player_address),
                                opponent: Option::None,
                                controller_has_black: StartVote { controller: Option::None, opponent: Option::None },
                                board: 0,
                                previous_board: 0,
                                nb_moves: 0,
                                prisoners: Prisoners { black: 0, white: 0 },
                                new_turn_player: Player::None,
                                result: GameResult { winner: Player::None, is_resign: false, double_score_diff: 0},
                            }
                        )
                    );
                },
                _ => {
                    panic_with_felt252('game_id already used');
                }
            };
        }

        fn join_game(ref world: IWorldDispatcher, game_id: felt252) -> bool {
            let game = get!(world, game_id, (Games));
            let mut newly_joined = false;
            match game.state {
                GameState::Inexistent => {
                    panic_with_felt252('Game does not exist');
                },
                GameState::Created => {
                    let player_address = get_caller_address();
                    match (game.controller, game.opponent) {
                        (Option::None, _) => {
                            panic_with_felt252('Unexpected uncontrolled game');
                        },
                        (_, Option::Some(opponent)) => {
                            panic_with_felt252('Unexpected Created game state');
                        },
                        (Option::Some(controller), _) => {
                            if controller != player_address {
                                set!(
                                    world,
                                    (
                                        Games {
                                            game_id,
                                            state: GameState::Joined,
                                            controller: game.controller,
                                            opponent: Option::Some(player_address),
                                            controller_has_black: StartVote { controller: Option::None, opponent: Option::None },
                                            board: game.board,
                                            previous_board: game.previous_board,
                                            nb_moves: game.nb_moves,
                                            prisoners: game.prisoners,
                                            new_turn_player: game.new_turn_player,
                                            result: game.result,
                                        }
                                    )
                                );
                                newly_joined = true;    
                            };
                        }
                    };
                },
                GameState::Joined => {
                    let player_address = get_caller_address();
                    match (game.controller, game.opponent) {
                        (Option::Some(controller), Option::Some(opponent)) => {
                            if controller != player_address && opponent != player_address {
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

        fn set_black(ref world: IWorldDispatcher, game_id: felt252, is_controller: bool) {
            let player_address = get_caller_address();
            let game = get!(world, game_id, (Games));
            if game.state != GameState::Joined {
                panic!("Not in 'Joined' state");
            }
            let player_vote = Option::Some(is_controller);
            if game.controller == Option::Some(player_address) {
                let opponent_vote = game.controller_has_black.opponent;
                if opponent_vote == player_vote {
                    set!(
                        world, 
                        Games {
                            game_id,
                            state: GameState::Ongoing,  // Start game
                            controller: game.controller,
                            opponent: game.opponent,
                            controller_has_black: StartVote { controller: player_vote, opponent: opponent_vote },
                            board: game.board,
                            previous_board: game.previous_board,
                            nb_moves: game.nb_moves,
                            prisoners: game.prisoners,
                            new_turn_player: Player::Black,
                            result: game.result,
                        }
                    );    
                } else {
                    set!(
                        world, 
                        Games {
                            game_id,
                            state: game.state,
                            controller: game.controller,
                            opponent: game.opponent,
                            controller_has_black: StartVote { controller: player_vote, opponent: opponent_vote },
                            board: game.board,
                            previous_board: game.previous_board,
                            nb_moves: game.nb_moves,
                            prisoners: game.prisoners,
                            new_turn_player: game.new_turn_player,
                            result: game.result,
                        }
                    );
                };
            } else if game.opponent == Option::Some(player_address) {
                let controller_vote = game.controller_has_black.controller;
                if controller_vote == player_vote {
                    set!(
                        world, 
                        Games {
                            game_id,
                            state: GameState::Ongoing,  // Start game
                            controller: game.controller,
                            opponent: game.opponent,
                            controller_has_black: StartVote { controller: controller_vote, opponent: player_vote },
                            board: game.board,
                            previous_board: game.previous_board,
                            nb_moves: game.nb_moves,
                            prisoners: game.prisoners,
                            new_turn_player: Player::Black,
                            result: game.result,
                        }
                    );    
                } else {
                    set!(
                        world, 
                        Games {
                            game_id,
                            state: game.state,
                            controller: game.controller,
                            opponent: game.opponent,
                            controller_has_black: StartVote { controller: controller_vote, opponent: player_vote },
                            board: game.board,
                            previous_board: game.previous_board,
                            nb_moves: game.nb_moves,
                            prisoners: game.prisoners,
                            new_turn_player: game.new_turn_player,
                            result: game.result,
                        }
                    );
                };
            };
        }

        fn play_move(ref world: IWorldDispatcher, game_id: felt252, position: Position) {
            let player_address = get_caller_address();
            let game = get!(world, game_id, (Games));

            if game.state != GameState::Ongoing {
                panic!("Not in 'Ongoing' state");
            };
            let player: Player = get_player(@game, player_address);
            assert!(player == game.new_turn_player, "Not player's turn.");
            let mut new_game = game.clone();
            applyMove(ref new_game, @game, player, position);
            emit!(world, Moved {
                game_id,
                move_nb: new_game.nb_moves,
                player,
                position,
            });
            set!(world, (new_game));
        }
    }
    
    fn get_player(game: @Games, player_address: ContractAddress) -> Player {
        let mut player = Player::None;
        if *game.controller == Option::Some(player_address) || *game.opponent == Option::Some(player_address) {
            if *game.state == GameState::Created || *game.state == GameState::Joined {
                panic!("Players not yet determined");
            };
            let controller_has_black: bool = (*game.controller_has_black.controller).unwrap();  // votes are identical
            if *game.controller == Option::Some(player_address) {
                if controller_has_black {
                    player =  Player::Black;
                } else {
                    player =  Player::White;
                };
            } else {
                if controller_has_black {
                    player =  Player::White;
                } else {
                    player = Player::Black;
                };
            }
        } else {
            panic!("Not a player in this game.");
        };
        player
    }
}
