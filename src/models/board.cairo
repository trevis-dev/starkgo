use core::option::OptionTrait;
use core::array::ArrayTrait;
use core::fmt::{Display, Formatter, Error};
use starkgo::models::group::remove_dead_stones;

const GRID_SIZE: usize = 9;
const BIT_MASK: u256 = 0b11; // Mask for extracting 2 bits to store None vs Black vs White stone on each of 81 intersections;

type Board = u256;

fn pow2(exp: usize) -> u256 {
    let mut idx: usize = 0;
    let mut res: u256 = 1;
    while idx < exp {
        res *= 2;
        idx += 1;
    };
    res
}

fn pow2_128(exp: usize) -> u128 {
    let mut idx: usize = 0;
    let mut res: u128 = 1;
    while idx < exp {
        res *= 2;
        idx += 1;
    };
    res
}

fn expand_mask(mask: u128) -> u256 {
    // Convert 1 bit flags to 0b11 
    let mut result: u256 = 0;
    let mut current_bit_position: usize = 0;
    let mut remainder = mask;
    while remainder > 0 {
        if remainder % 2 == 1 {
            result += 3 * pow2(current_bit_position);
        }
        current_bit_position += 2;
        remainder /= 2;
    };
    result
}

fn _set_value(ref board: Board, x: usize, y: usize, value: u8) -> Option<Capture> {
    // Check that position is empty before calling
    let position: usize = (x * GRID_SIZE + y) * 2;
    let positioned_new_value: u256 = (value.into()) * pow2(position);

    board = board | positioned_new_value;
    match remove_dead_stones(@board, x, y, value) {
        Option::Some(move_capture) => {
            let capture_mask: u256 = expand_mask(move_capture.stones_mask);
            board = board & ~capture_mask;
            Option::Some(Capture { black: move_capture.black, white: move_capture.white })
        },
        Option::None => { return Option::None; }
    }
}

fn _get_value(board: @Board, x: usize, y: usize) -> u8 {
    let bit_position = pow2((x * GRID_SIZE + y) * 2);
    ((*board / bit_position) % 4).try_into().unwrap()
}

fn getLabel(value: u8) -> ByteArray  {
    match value {
        0 => " + ",
        1 => " X ",
        2 => " O ",
        _ => " ? "
    }
}

fn print_board(board: @Board) {
    println!("    1   2   3   4   5   6   7   8   9");
    let row_labels: Array<ByteArray> = array!["A", "B", "C", "D", "E", "F", "G", "H", "I"];
    let mut x_idx: usize = 0;
    while x_idx < GRID_SIZE {
        print!("{} -", row_labels[x_idx]);
        let mut y_idx: usize = 0;        
        while y_idx < GRID_SIZE {
            let value = _get_value(board, x_idx, y_idx);
            let label = getLabel(value);
            print!("{label}-");
            y_idx += 1;
        };
        println!("");
        if x_idx < GRID_SIZE - 1 {
            println!("    |   |   |   |   |   |   |   |   |");
        }
        x_idx += 1;
    };
}

#[inline(always)]
fn check_move_allowed(board: @Board, player: Player, x: usize, y: usize) -> (usize, usize, u8) {
    assert!(x < GRID_SIZE && y < GRID_SIZE, "Coordinates out of bounds");
    assert!(_get_value(board, x, y) == 0, "Occupied");
    let value: u8 = player.into();
    assert!(value <= 2, "Value must be 0, 1, or 2");
    (x, y, value)
}

fn add_move(ref board: Board, player: Player, x: usize, y: usize) -> Option<Capture> {
    check_move_allowed(@board, player, x, y);
    let capture = _set_value(ref board, x, y, player.into());
    capture
}

fn get_move(board: @Board, x: usize, y: usize) -> u8 {
    assert!(x < GRID_SIZE && y < GRID_SIZE, "Coordinates out of bounds");
    _get_value(board, x, y)
}

#[derive(Drop, PartialEq)]
struct Capture {
    black: u32,
    white: u32,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
struct Prisoners {
    black: u32,
    white: u32,
}

impl CaptureIntoPrisoners of Into<Capture, Prisoners> {
    fn into(self: Capture) -> Prisoners {
        Prisoners { black: self.white, white: self.black }
    }
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
struct Position {
    x: Row,
    y: Column,
}


#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum Row {
    None,
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I
}


impl RowIntoUsize of Into<Row, usize> {
    fn into(self: Row) -> usize {
        match self {
            Row::None => 1000,
            Row::A => 0,
            Row::B => 1,
            Row::C => 2,
            Row::D => 3,
            Row::E => 4,
            Row::F => 5,
            Row::G => 6,
            Row::H => 7,
            Row::I => 8,
        }
    }
}
impl UsizeIntoRow of Into<usize, Row> {
    fn into(self: usize) -> Row {
        match self {
            0 => Row::A,
            1 => Row::B,
            2 => Row::C,
            3 => Row::D,
            4 => Row::E,
            5 => Row::F,
            6 => Row::G,
            7 => Row::H,
            8 => Row::I,
            _ => Row::None,
        }
    }
}

impl RowIntoByteArray of Into<Row, ByteArray> {
    fn into(self: Row) -> ByteArray {
        match self {
            Row::None => "None",
            Row::A => "A",
            Row::B => "B",
            Row::C => "C",
            Row::D => "D",
            Row::E => "E",
            Row::F => "F",
            Row::G => "G",
            Row::H => "H",
            Row::I => "I",
        }
    }
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum Column {
    None,
    One,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine
}

impl ColmumnIntoUsize of Into<Column, usize> {
    fn into(self: Column) -> usize {
        match self {
            Column::None => 1000,
            Column::One => 0,
            Column::Two => 1,
            Column::Three => 2,
            Column::Four => 3,
            Column::Five => 4,
            Column::Six => 5,
            Column::Seven => 6,
            Column::Eight => 7,
            Column::Nine => 8,
        }
    }
}
impl ColmumnIntoByteArray of Into<Column, ByteArray> {
    fn into(self: Column) -> ByteArray {
        match self {
            Column::None => "None",
            Column::One => "1",
            Column::Two => "2",
            Column::Three => "3",
            Column::Four => "4",
            Column::Five => "5",
            Column::Six => "6",
            Column::Seven => "7",
            Column::Eight => "8",
            Column::Nine => "9",
        }
    }
}
impl UsizeIntoColmumn of Into<usize, Column> {
    fn into(self: usize) -> Column {
        match self {
            0 => Column::One,
            1 => Column::Two,
            2 => Column::Three,
            3 => Column::Four,
            4 => Column::Five,
            5 => Column::Six,
            6 => Column::Seven,
            7 => Column::Eight,
            8 => Column::Nine,
            _ => Column::None,
        }
    }
}
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum Player {
    None,
    Black,
    White,
}

impl PlayerIntoU8 of Into<Player, u8> {
    fn into(self: Player) -> u8 {
        match self {
            Player::None => 0,
            Player::Black => 1,
            Player::White => 2,
        }
    }
}

impl BitNotPlayer of BitNot<Player> {
    fn bitnot(a: Player) -> Player {
        match a {
            Player::None => Player::None,
            Player::Black => Player::White,
            Player::White => Player::Black
        }
    }
}

impl PlayerIntoByteArray of Into<Player, ByteArray> {
    fn into(self: Player) -> ByteArray {
        match self {
            Player::None => "None",
            Player::Black => "Black",
            Player::White => "White",
        }
    }
}

impl PointDisplay of Display<Player> {
    fn fmt(self: @Player, ref f: Formatter) -> Result<(), Error> {
        let player_name: ByteArray = (*self).into();

        write!(f, "{player_name}")
    }
}

impl PositionDisplay of Display<Position> {
    fn fmt(self: @Position, ref f: Formatter) -> Result<(), Error> {
        let x: ByteArray = (*self.x).into();
        let y: ByteArray = (*self.y).into();

        write!(f, "{x}{y}")
    }
}

#[cfg(test)]
mod tests {
    use super::{Board, Capture, Position, Player, Row, Column, add_move, get_move, print_board};

    #[test]
    #[available_gas(13400000)]
    fn test_first_move_gaz() {
        let mut board: Board = 0;
        let _ = add_move(ref board, Player::Black, x: Row::D.into(), y: Column::Six.into());
    }

    #[test]
    #[available_gas(2600000)]
    fn test_get_move_gaz() {
        // let mut board: Board = 0;
        // let _ = add_move(ref board, Player::Black, Position { x: Row::D, y: Column::Six });
        let mut board: Board = 18446744073709551616;
        // white plays elsewhere
        assert(get_move(@board, x: Row::D.into(), y: Column:: Six.into()) == Player::Black.into(), 'Wrong player');
        assert(get_move(@board, x: Row::E.into(), y: Column:: Five.into()) == Player::None.into(), 'Wrong player');
    }

    // println!("board: {board}");
    // print_board(@board);

    #[test]
    #[available_gas(50300000)]
    fn test_multiple_moves() {
        let mut board: Board = 0;
        let _ = add_move(ref board, Player::Black, x: Row::D.into(), y: Column::Six.into() );
        assert(board == 18446744073709551616, 'Incorrect state after 1st move.');
        let _ = add_move(ref board, Player::White, x: Row::E.into(), y: Column::Five.into() );
        assert(board == 2417870085973332058963968, 'Incorrect state after 2nd move.');

        let _ = add_move(ref board, Player::Black, x: Row::I.into(), y: Column::Nine.into() );
        let _ = assert(board == 1461501637330902918203687250586368992987991506944, 'Incorrect state after 3rd move.');
        assert(get_move(@board, x: Row::E.into(), y: Column::Five.into() ) == Player::White.into(), 'Wrong player');
    }

    #[test]
    #[should_panic(expected: ("Occupied", ))]
    fn test_position_occupied() {
        let mut board: Board = 18446744073709551616;
        let _ = add_move(ref board, Player::Black, x: Row::D.into(), y: Column::Six.into());
    }
    
    #[test]
    #[available_gas(16400000)]
    fn test_capture_stone() {
        // let mut board: Board = 0;
        // let _ = add_move(ref board, Player::Black, Position { x: Row::D, y: Column::Six });
        // let _ = add_move(ref board, Player::White, Position  {x: Row::D, y: Column::Five });
        // let _ = add_move(ref board, Player::Black, Position { x: Row::E, y: Column::Five });
        // // white plays elsewhere
        // let _ = add_move(ref board, Player::Black, Position { x: Row::D, y: Column::Four });
        // assert!(board == 1208954642652244345880576, "Incorrect state before capturing move");

        // =>
        let mut board: Board = 1208954642652244345880576;
        // white plays elsewhere
        let capture = add_move(ref board, Player::Black, x: Row::C.into(), y: Column::Five.into());
        assert(capture == Option::Some(Capture { black: 0, white: 1 }), 'Incorrect capture');
        assert(board == 1208945419297799677149184, 'Incorrect state after capture.');
    }
}
