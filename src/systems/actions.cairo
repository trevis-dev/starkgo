
use starkgo::models::{
    board::{Position},
    game::{GameState, Player, Prisoners},
};

#[dojo::interface]
trait IActions {
    fn create_game(ref world: IWorldDispatcher, game_id: felt252);
    fn join_game(ref world: IWorldDispatcher, game_id: felt252) -> bool;
    fn set_black(ref world: IWorldDispatcher, game_id: felt252, to_controller: bool);
    fn play_move(ref world: IWorldDispatcher, game_id: felt252, x: usize, y: usize);
    fn pass(ref world: IWorldDispatcher, game_id: felt252);
    fn resign(ref world: IWorldDispatcher, game_id: felt252);
    fn mark_dead_stones(ref world: IWorldDispatcher, game_id: felt252, stones_mask: u128);
    
    fn game_state(world: @IWorldDispatcher, game_id: felt252) -> GameState;
    fn board(world: @IWorldDispatcher, game_id: felt252) -> u256;
    fn new_turn_player(world: @IWorldDispatcher, game_id: felt252) -> Player;
    fn nb_moves(world: @IWorldDispatcher, game_id: felt252) -> usize;
    fn prisoners(world: @IWorldDispatcher, game_id: felt252) -> Prisoners;
}

#[dojo::contract]
mod actions {
    use super::{ IActions };
    use starkgo::models::game::{ DeadStonesVote, Prisoners, Games, GameState, GameResult, StartVote, StartPlayerVote, applyMove};
    use starkgo::models::board::{ Board, Player, Position, Row, Column};
    use starknet::{ ContractAddress, get_caller_address };
    use core::num::traits::Zero;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Moved: Moved,
        Passed: Moved,
        Started: Moved,
        CountingStart: Moved,
        Resigned: Moved,
        Finished: Moved,
    }

    #[derive(Drop, Serde, starknet::Event)]
    struct Moved {
        #[key]
        game_id: felt252,
        is_pass: bool,
        is_resign: bool,
        move_nb: u32,
        player: Player,
        position: Position
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_game(ref world: IWorldDispatcher, game_id: felt252) {
            let player_address = get_caller_address();
            let game = get!(world, game_id, (Games));
            assert!(game.state == GameState::Inexistent, "game_id already used");
            let zero_address: ContractAddress = Zero::zero();
            check_not_zero(player_address);
            let emptyVote = StartPlayerVote { voted: false, controller_has_black: false };
            set!(
                world,
                (
                    Games {
                        game_id,
                        state: GameState::Created,
                        controller: player_address,
                        opponent: zero_address,
                        controller_has_black: StartVote { controller: emptyVote, opponent: emptyVote },
                        board: 0,
                        previous_board: 0,
                        nb_moves: 0,
                        prisoners: Prisoners { black: 0, white: 0 },
                        new_turn_player: Player::None,
                        last_passed: false,
                        last_move: (0, 0),
                        dead_stones: DeadStonesVote { controller: 0xffffffffffffffffffffffffffffffff, opponent: 0xffffffffffffffffffffffffffffffff },
                        result: GameResult { winner: Player::None, is_resign: false, double_score_diff: 0},
                    }
                )
            );
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
                    check_not_zero(player_address);
                    let zero_address: ContractAddress = Zero::zero();
                    if game.controller == zero_address {
                        panic_with_felt252('Unexpected uncontrolled game');
                    };
                    if game.opponent != zero_address {
                        panic_with_felt252('Unexpected Created game state');
                    };
                    if player_address != game.controller {
                        set!(
                            world,
                            (
                                Games {
                                    game_id,
                                    state: GameState::Joined,
                                    controller: game.controller,
                                    opponent: player_address,
                                    controller_has_black: game.controller_has_black,
                                    board: game.board,
                                    previous_board: game.previous_board,
                                    nb_moves: game.nb_moves,
                                    prisoners: game.prisoners,
                                    new_turn_player: game.new_turn_player,
                                    last_passed: game.last_passed,
                                    last_move: game.last_move,
                                    dead_stones: game.dead_stones,
                                    result: game.result,
                                }
                            )
                        );
                        newly_joined = true;
                    };
                },
                GameState::Joined | GameState::Ongoing => {
                    let player_address = get_caller_address();
                    check_not_zero(player_address);
                    let zero_address: ContractAddress = Zero::zero();
                    if game.controller == zero_address || game.opponent == zero_address {
                        panic_with_felt252('Unexpected Joined game state');
                    };
                    if game.controller != player_address && game.opponent != player_address {
                        panic_with_felt252('Game can no longer be joined');
                    }; // else don't panic, all good, just already joined.
                },
                _ => {
                    panic_with_felt252('Game can no longer be joined');
                }
            };
            newly_joined
        }

        fn set_black(ref world: IWorldDispatcher, game_id: felt252, to_controller: bool) {
            let player_address = get_caller_address();
            check_not_zero(player_address);
            let game = get!(world, game_id, (Games));
            if game.state != GameState::Joined {
                panic!("Not in 'Joined' state");
            }
            let player_vote = StartPlayerVote { voted: true, controller_has_black: to_controller };
            let mut new_game = game.clone();
            if game.controller == player_address {
                if game.controller_has_black.controller == player_vote {
                    return;
                };
                new_game.controller_has_black.controller = player_vote;
                if new_game.controller_has_black.opponent == player_vote {
                    new_game.state = GameState::Ongoing;
                    new_game.new_turn_player = Player::Black;
                    emit!(world, (Event::Started ( Moved {
                        game_id,
                        move_nb: 0,
                        player: Player::None,
                        position: Position { x: Row::None, y: Column::None },
                        is_pass: false,
                        is_resign: false,
                    })));               
                };
                set!(world, (new_game));
            } else if game.opponent == player_address {
                if game.controller_has_black.opponent == player_vote {
                    return;
                };
                new_game.controller_has_black.opponent = player_vote;
                if game.controller_has_black.controller == player_vote {
                    new_game.state = GameState::Ongoing;
                    new_game.new_turn_player = Player::Black;
                    emit!(world, (Event::Started ( Moved {
                        game_id,
                        move_nb: 0,
                        player: Player::None,
                        position: Position { x: Row::None, y: Column::None },
                        is_pass: false,
                        is_resign: false,
                    })));                
                };
                set!(world, (new_game));
            } else {
                panic!("Not a player in this game.");
            };
        }

        fn play_move(ref world: IWorldDispatcher, game_id: felt252, x: usize, y: usize) {
            let game = get!(world, game_id, (Games));
            assert!(game.state == GameState::Ongoing, "Not in 'Ongoing' state");

            let player_address = get_caller_address();
            check_not_zero(player_address);
            let player: Player = get_player(@game, player_address);
            assert!(player == game.new_turn_player, "Not player's turn.");

            let mut new_game = game.clone();
            applyMove(ref new_game, @game, player, x, y);
            emit!(world, (Event::Moved (Moved {
                game_id,
                move_nb: new_game.nb_moves,
                player,
                position: Position { x: x.into(), y: y.into() },
                is_pass: false,
                is_resign: false,
            })));
            set!(world, (new_game));
        }

        fn pass(ref world: IWorldDispatcher, game_id: felt252) {
            let game = get!(world, game_id, (Games));
            assert!(game.state == GameState::Ongoing, "Not in 'Ongoing' state");

            let player_address = get_caller_address();
            check_not_zero(player_address);
            let player: Player = get_player(@game, player_address);
            assert!(player == game.new_turn_player, "Not player's turn.");
            let mut new_game = game.clone();
            new_game.new_turn_player = ~player;
            new_game.nb_moves += 1;
            new_game.last_passed = true;
            if game.last_passed {
                new_game.state = GameState::Counting;
                emit!(world,( Event::CountingStart ( Moved {
                    game_id,
                    move_nb: new_game.nb_moves,
                    player: Player::None,
                    position: Position { x: Row::None, y: Column::None },
                    is_pass: true,
                    is_resign: false,
                })));
            }
            emit!(world, (Event::Passed ( Moved {
                game_id,
                move_nb: new_game.nb_moves,
                player,
                position : Position {x: Row::None, y: Column::None},
                is_pass: true,
                is_resign: false,
            })));
            set!(world, (new_game));
        }

        fn resign(ref world: IWorldDispatcher, game_id: felt252) {
            let game = get!(world, game_id, (Games));
            assert!(game.state == GameState::Ongoing, "Not in 'Ongoing' state");

            let player_address = get_caller_address();
            check_not_zero(player_address);
            let player: Player = get_player(@game, player_address);
            assert!(player == game.new_turn_player, "Not player's turn.");
            let mut new_game = game.clone();
            if player == Player::White {
                new_game.result = GameResult { winner: Player::Black, is_resign: true, double_score_diff: 0 };
            } else {
                new_game.result = GameResult { winner: Player::White, is_resign: true, double_score_diff: 0 };
            }
            
            new_game.state = GameState::Finished;
            emit!(world,( Event::Finished ( Moved {
                game_id,
                move_nb: new_game.nb_moves,
                player,
                position: Position { x: Row::None, y: Column::None },
                is_pass: false,
                is_resign: true,
            })));
            set!(world, (new_game));
        }

        fn mark_dead_stones(ref world: IWorldDispatcher, game_id: felt252, stones_mask: u128) {
            let player_address = get_caller_address();
            check_not_zero(player_address);
            let game = get!(world, game_id, (Games));
            if game.state != GameState::Counting {
                panic!("Not in 'Counting' state");
            }
            let mut new_game = game.clone();
            if game.controller == player_address {
                if game.dead_stones.controller == stones_mask {
                    return;
                }
                new_game.dead_stones = DeadStonesVote { controller: stones_mask, opponent: new_game.dead_stones.opponent };
                
            } else if game.opponent == player_address {
                if game.dead_stones.opponent == stones_mask {
                    return;
                }
                new_game.dead_stones = DeadStonesVote { controller: new_game.dead_stones.controller, opponent: stones_mask };
            } else {
                panic!("Not a player in this game.");
            };
            if new_game.dead_stones.controller == new_game.dead_stones.opponent {
                new_game.state = GameState::Finished;
                score_game(ref new_game);
                emit!(world,( Event::Finished ( Moved {
                    game_id,
                    move_nb: new_game.nb_moves,
                    player: Player::None,
                    position: Position { x: Row::None, y: Column::None },
                    is_pass: false,
                    is_resign: false,
                })));
            }
            set!(world, (new_game));
        }

        fn game_state(world: @IWorldDispatcher, game_id: felt252) -> GameState {
            let game = get!(world, game_id, (Games));
            game.state
        }
        fn board(world: @IWorldDispatcher, game_id: felt252) -> u256 {
            let game = get!(world, game_id, (Games));
            assert!(game.state != GameState::Inexistent, "No game with that game_id");
            game.board
        }
        fn new_turn_player(world: @IWorldDispatcher, game_id: felt252) -> Player {
            let game = get!(world, game_id, (Games));
            assert!(game.state != GameState::Inexistent, "No game with that game_id");
            game.new_turn_player
        }
        fn nb_moves(world: @IWorldDispatcher, game_id: felt252) -> usize {
            let game = get!(world, game_id, (Games));
            assert!(game.state != GameState::Inexistent, "No game with that game_id");
            game.nb_moves
        }
        fn prisoners(world: @IWorldDispatcher, game_id: felt252) -> Prisoners {
            let game = get!(world, game_id, (Games));
            assert!(game.state != GameState::Inexistent, "No game with that game_id");
            game.prisoners
        }
    }

    fn get_player(game: @Games, player_address: ContractAddress) -> Player {
        let mut player = Player::None;
        if *game.controller == player_address || *game.opponent == player_address {
            assert!(*game.state != GameState::Created && *game.state != GameState::Joined, "Players not yet determined");
            let controller_has_black: bool = *game.controller_has_black.controller.controller_has_black;  // votes are identical
            if *game.controller == player_address {
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

    fn score_game(ref game: Games) {
        // todo
    }

    #[inline(always)]
    fn check_not_zero(address: ContractAddress) {
        if address == Zero::zero() {
            panic!("Call from 0");
        };
    }
}
