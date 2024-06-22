use starknet::ContractAddress;
use starkgo::models::board::{Board, Prisoners, Player, Position, add_move};

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
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
struct StartPlayerVote {
    voted: bool,
    controller_has_black: bool,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
struct StartVote {
    controller: StartPlayerVote,
    opponent: StartPlayerVote,
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
    controller: ContractAddress,
    opponent: ContractAddress,
    controller_has_black: StartVote,
    board: Board,
    previous_board: Board,  // used for ko
    nb_moves: u32,
    prisoners: Prisoners,
    new_turn_player: Player,
    last_passed: bool,
    last_move: (usize, usize),
    result: GameResult,
}

impl AddEqPrisoners of AddEq<Prisoners> {
    fn add_eq(ref self: Prisoners, other: Prisoners) {
        self.black += other.black;
        self.white += other.white;
    }
}

fn applyMove(ref new_game: Games, game: @Games, player: Player, x: usize, y: usize) -> Games {
    let previous_board = *game.previous_board;
    let current_board = *game.board;
    let capture = add_move(ref new_game.board, player, x, y);
    if let Option::Some(val) = capture {
        new_game.prisoners += val.into();
    }
    assert!(new_game.board != previous_board, "Move forbidden by ko rule");
    new_game.previous_board = current_board;
    new_game.new_turn_player = ~player;
    new_game.nb_moves += 1;
    new_game.last_passed = false;
    new_game.last_move = (x, y);
    new_game
}
