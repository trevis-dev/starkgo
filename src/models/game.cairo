use starknet::ContractAddress;
use starkgo::models::board::{Board, Capture, Player, Move, PlayerMove, add_move};

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Print)]
enum GameState {
    Inexistent,
    Created,
    Joined,
    Ongoing,
    Finished,
}

impl GameStateIntoByteArray of Into<GameState, ByteArray> {
    fn into(self: GameState) -> ByteArray {
        match self {
            GameState::Inexistent => "Inexistent",
            GameState::Created => "Created",
            GameState::Joined => "Joined",
            GameState::Ongoing => "Ongoing",
            GameState::Finished => "Finished"
        }
    }
}


#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
struct StartVote {
    controller: Option<bool>,
    opponent: Option<bool>,
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
    previous_board: Board,  // used for ko
    nb_moves: u32,
    capture: Capture,
    new_turn_player: Player,
    result: GameResult,
}

impl AddEqCapture of AddEq<Capture> {
    fn add_eq(ref self: Capture, other: Capture) {
        self.black += other.black;
        self.white += other.white;
    }
}

fn applyMove(game: @Games, player: Player, move: Move) -> Games {
    let mut new_game = game.clone();
    match move {
        Move::Play(player_move) => {
            let previous_board = *game.previous_board;
            let current_board = *game.board;
            let capture = add_move(ref new_game.board, player, player_move.move_position);
            if let Option::Some(val) = capture {
                new_game.capture += val;
            }
            if new_game.board == previous_board {
                panic!("Move forbidden by ko rule");
            };
            new_game.previous_board = current_board;
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
