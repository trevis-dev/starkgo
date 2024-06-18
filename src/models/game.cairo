use starknet::ContractAddress;
use starkgo::models::board::{Board, Prisoners, Player, Move, PlayerMove, add_move, Position};

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
    prisoners: Prisoners,
    new_turn_player: Player,
    result: GameResult,
}

impl AddEqPrisoners of AddEq<Prisoners> {
    fn add_eq(ref self: Prisoners, other: Prisoners) {
        self.black += other.black;
        self.white += other.white;
    }
}

fn applyGameMove(ref new_game: Games, game: @Games, player: Player, position: Position) -> Games {
    let previous_board = *game.previous_board;
    let current_board = *game.board;
    let capture = add_move(ref new_game.board, player, position);
    if let Option::Some(val) = capture {
        new_game.prisoners += val.into();
    }
    assert!(new_game.board != previous_board, "Move forbidden by ko rule");
    new_game.previous_board = current_board;
    if player == Player::Black {
        new_game.new_turn_player = Player::White;
    } else {
        new_game.new_turn_player = Player::Black;
    };
    new_game.nb_moves += 1;
    new_game
}

fn applyMove(game: @Games, player: Player, move: Move) -> Games {
    let mut new_game = game.clone();
    match move {
        Move::Play(player_move) => {
            applyGameMove(ref new_game, game, player, player_move.move_position);
        },
        _ => { 
            // todo
        }
    }
    new_game
}
