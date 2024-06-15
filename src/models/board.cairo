use core::array::ArrayTrait;

const GRID_SIZE: usize = 9;
const BIT_MASK: u256 = 0b11; // Mask for extracting 2 bits to store None vs Black vs White stone on each of 81 intersections;

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

fn move(ref grid: u256, position: Position, player: Player) {
    set_value(ref grid, position.x.into(), position.y.into(), player.into());
}


#[derive(Serde, Copy, Drop, Introspect)]
struct Position {
    x: Row,
    y: Column,
}


#[derive(Serde, Copy, Drop, Introspect)]
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


#[derive(Serde, Copy, Drop, Introspect)]
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


#[derive(Serde, Copy, Drop, Introspect)]
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

fn main() {
    let mut grid: u256 = 0;
    let black = Player::Black;
    let white = Player::White;
    move(ref grid, Position {x: Row::D, y: Column::Six }, black);
    move(ref grid, Position {x: Row::E, y: Column::Five}, white);
    move(ref grid, Position {x: Row::E, y: Column::Six }, black);

    print_board(@grid);
    println!(" ");
}
