use core::array::ArrayTrait;
use core::fmt::{Display, Formatter, Error};

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

fn set_value(ref grid: u256, x: usize, y: usize, value: u8) {
    assert!(x < GRID_SIZE && y < GRID_SIZE, "Coordinates out of bounds");
    assert!(value <= 2, "Value must be 0, 1, or 2");

    let position: usize = (y * GRID_SIZE + x) * 2;
    let bit_clear_mask = ~(BIT_MASK * pow2(position));
    let positioned_new_value: u256 = (value.into()) * pow2(position);

    grid = (grid & bit_clear_mask ) | positioned_new_value;
}

fn get_value(grid: @u256, x: usize, y: usize) -> u8 {
    assert!(x < GRID_SIZE && y < GRID_SIZE, "Coordinates out of bounds");

    let bit_position = (y * GRID_SIZE + x) * 2;
    let bit_mask = BIT_MASK * pow2(bit_position);

    ((*grid & bit_mask) / pow2(bit_position)).try_into().unwrap()
}

fn getLabel(value: u8) -> ByteArray  {
    match value {
        0 => " + ",
        1 => " X ",
        2 => " O ",
        _ => " ? "
    }
}

fn print_board(board: @u256) {
    println!("    1   2   3   4   5   6   7   8   9");
    let row_labels: Array<ByteArray> = array!["A", "B", "C", "D", "E", "F", "G", "H", "I"];
    let mut x_idx: usize = 0;
    while x_idx < GRID_SIZE {
        print!("{} -", row_labels[x_idx]);
        let mut y_idx: usize = 0;        
        while y_idx < GRID_SIZE {
            let value = get_value(board, x_idx, y_idx);
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

fn move(ref grid: u256, player: Player, position: Position) {
    set_value(ref grid, position.x.into(), position.y.into(), player.into());
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


impl RowIntoFelt252 of Into<Row, usize> {
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

impl ColmumnIntoFelt252 of Into<Column, usize> {
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

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum Player {
    None,
    Black,
    White,
}

impl PlayerIntoFelt252 of Into<Player, u8> {
    fn into(self: Player) -> u8 {
        match self {
            Player::None => 0,
            Player::Black => 1,
            Player::White => 2,
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
    use super::{Position, Player, Row, Column, move, print_board, set_value};

    #[test]
    #[available_gas(12000000)]
    fn test_valid_range() {
        let mut grid: u256 = 0;
        move(ref grid, Player::Black, Position {x: Row::D, y: Column::Six });
        assert(grid == 79228162514264337593543950336, 'Incorrect state after 1st move.');
        move(ref grid, Player::White, Position {x: Row::E, y: Column::Five});
        assert(grid == 79230580365903566851893362688, 'Incorrect state after 2nd move.');
        move(ref grid, Player::Black, Position {x: Row::I, y: Column::Nine});
        assert(grid == 1461501637330902918282915413082186586507825905664, 'Incorrect state after 2nd move.');
    }


    #[test]
    #[should_panic(expected: ("Coordinates out of bounds", ))]
    #[available_gas(100000)]
    fn test_outside_range() {
        let mut grid: u256 = 0;
        set_value(ref grid, x: 10, y: 4, value: 1);
    }

    #[test]
    #[should_panic(expected: ("Value must be 0, 1, or 2", ))]
    #[available_gas(100000)]
    fn test_incorrect_value() {
        let mut grid: u256 = 0;
        set_value(ref grid, x: 5, y: 4, value: 4);
    }
}
