use starkgo::models::board::{Position, Row, Column};

# [derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum Move {
    Play: PlayerMove,
    Pass: PlayerMove,
    Resign: PlayerMove,
}

# [derive(Serde, Copy, Drop, Introspect, PartialEq)]
struct PlayerMove {
    move_position: Position,
    is_pass: bool,
    is_resign: bool,
}

fn main() {
    let _pass_move = Move::Pass(PlayerMove { 
        move_position: Position { x: Row::None, y: Column::None },
        is_pass: true,
        is_resign: false,
    });
}
