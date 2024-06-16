use starknet::ContractAddress;
use starkgo::models::board::{Board, Player, add_move};
use starkgo::models::move::{Move, PlayerMove};

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Print)]
enum GameState {
    Inexistent,
    Created,
    Joined,
    Ongoing,
    Finished,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
struct StartVote {
    controller: Option<bool>,
    opponent: Option<bool>,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
struct Capture {
    black: u8,
    white: u8,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Games {
    #[key]
    game_id: felt252,
    state: GameState,
    controller: Option<ContractAddress>,
    opponent: Option<ContractAddress>,
    controller_has_black: StartVote,
    board: Board,
    capture: Capture,
    new_turn_player: Player
}

fn applyMove(game: @Games, player: Player, move: Move) -> Games {
    let mut new_game = Games {
        game_id: *game.game_id,
        state: *game.state,
        controller: *game.controller,
        opponent: *game.opponent,
        controller_has_black: *game.controller_has_black,
        board: *game.board,
        capture: *game.capture,
        new_turn_player: *game.new_turn_player
    };
    match move {
        Move::Play(player_move) => {
            add_move(ref new_game.board, player, player_move.move_position.unwrap());
        },
        _ => { 
            // todo
        }
    }
    new_game
}    
