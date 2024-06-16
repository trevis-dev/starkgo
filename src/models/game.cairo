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

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
struct GameResult {
    winner: Player,
    is_resign: bool,
    double_score_diff: u32,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq)]
#[dojo::model]
struct Games {
    #[key]
    game_id: felt252,
    state: GameState,
    controller: Option<ContractAddress>,
    opponent: Option<ContractAddress>,
    controller_has_black: StartVote,
    board: Board,
    nb_moves: u32,
    capture: Capture,
    new_turn_player: Player,
    result: GameResult,
}

fn applyMove(game: @Games, player: Player, move: Move) -> Games {
    let mut new_game = game.clone();
    match move {
        Move::Play(player_move) => {
            add_move(ref new_game.board, player, player_move.move_position);
            if player == Player::Black {
                new_game.new_turn_player = Player::White;
            } else {
                new_game.new_turn_player = Player::Black;
            };
            new_game.nb_moves += 1;
        },
        _ => { 
            // todo
        }
    }
    new_game
}
