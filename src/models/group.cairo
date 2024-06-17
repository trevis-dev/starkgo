use core::array::ArrayTrait;
use starkgo::models::{game::Player, board::{Board, Position, GRID_SIZE, pow2_128, _get_value}};


#[derive(Copy, Drop)]
struct Group {
    value: u8,
    n_stones: usize,
    stones_mask: u128,
    n_liberties: usize,
    liberties_mask: u128,
}

fn get_neighbors(x: usize, y: usize) -> Array<(usize, usize)> {
    let mut res: Array<(usize, usize)> = array![];
    if x > 0 {
        res.append((x-1, y));
    }
    if y > 0 {
        res.append((x, y-1));
    }
    if x < GRID_SIZE - 1 {
        res.append((x+1, y));
    }
    if y < GRID_SIZE - 1 {
        res.append((x, y+1));
    }
    res
}


#[inline(always)]
fn position_to_int(x: usize, y: usize) -> usize {
    x * GRID_SIZE + y
}

#[inline(always)]
fn position_to_mask(x: usize, y: usize ) -> u128 {
    pow2_128(position_to_int(x, y).into())
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
struct MoveCapture {
    stones_mask: u128,
    black: u32,
    white: u32,
}


fn remove_dead_stones(board: @u256, x: usize, y:usize, value: u8) -> Option<MoveCapture> {
    let mut positions_checked_mask: u128 = 0;
    let mut positions_to_check = get_neighbors(x, y);
    positions_to_check.append((x, y)); // Make sure we go through it after the other if does not belong to any group
    let mut n_positions_to_check = positions_to_check.len();
    let mut n_positions_checked: usize = 0;
    let mut stones_captured = 0;
    let mut capture_mask: u128 = 0;
    let mut capture_own = false;
    let mut capture_other = false;
    while n_positions_checked < n_positions_to_check {
        let (new_x, new_y) = *positions_to_check.at(n_positions_checked);
        let new_position_mask = position_to_mask(new_x, new_y);
        n_positions_checked += 1;
        if new_position_mask & positions_checked_mask == 0 {
            positions_checked_mask = positions_checked_mask | new_position_mask;
            let other_value = _get_value(board, new_x, new_y);
            if other_value != 0 {
                let mut group = get_group_mask_and_liberties(board, new_x, new_y, other_value);
                positions_checked_mask = positions_checked_mask | group.stones_mask;
                if group.n_liberties == 0 {
                    if group.value == value {
                        capture_own = true;
                    } else {
                        capture_other = true;
                        capture_mask = capture_mask | group.stones_mask;
                        stones_captured += group.n_stones;
                    }
                };
            };
        };
    };
    if capture_own && !capture_other {
        panic!("Own group sacrificed.");  // Not allowed with these rules.
    }
    if capture_other {
        let (black, white) = match value {
            0 => panic!("What is this?"),
            1 => { (0, stones_captured) },
            2 => { (stones_captured, 0) },
            _ => panic!("What is this?")
        };
        Option::Some(MoveCapture {
            stones_mask: capture_mask,
            black,
            white,
        })

    } else {
        Option::None
    }
}


fn get_group_mask_and_liberties(board: @u256, x: usize, y:usize, value: u8) -> Group {
    let stone_mask = position_to_mask(x, y);
    let mut stones_mask = stone_mask;
    let mut positions_checked_mask = stone_mask;  // don't got there twice
    let mut n_positions_checked: usize = 0;  // As the one above won't be in the list
    
    let mut n_stones: usize = 1;

    let mut n_liberties: usize = 0;
    let mut liberties_mask: u128 = 0;
    
    let mut positions_to_check_mask = stone_mask;
    
    let mut positions_to_check = get_neighbors(x, y);
    let positions_to_check_copy = positions_to_check.clone();
    let mut n_positions_to_check: usize = positions_to_check.len();
    let mut idx: usize = 0;
    while idx < n_positions_to_check{
        let (n_x, n_y) = *positions_to_check_copy.at(idx);
        positions_to_check_mask = positions_to_check_mask | position_to_mask(n_x, n_y);
        idx+=1
    };

    while n_positions_checked < n_positions_to_check {
        let (new_x, new_y) = *positions_to_check.at(n_positions_checked);
        let new_position_mask = position_to_mask(new_x, new_y);
        n_positions_checked += 1;
        positions_checked_mask = positions_checked_mask | new_position_mask;
        let other_value = _get_value(board, new_x, new_y);
        if other_value == value {
            n_stones += 1;
            stones_mask = stones_mask | new_position_mask;
            let mut potential_positions_to_check = get_neighbors(new_x, new_y);
            while let Option::Some(pos) = potential_positions_to_check.pop_front() {
                let (pos_x, pos_y) = pos;
                let pos_mask = position_to_mask(pos_x, pos_y);
                if (pos_mask & positions_to_check_mask) == 0 {
                    positions_to_check_mask = positions_to_check_mask | pos_mask;
                    positions_to_check.append(pos);
                    n_positions_to_check += 1
                };
            };
        } else if other_value == 0 {
            liberties_mask = liberties_mask | new_position_mask;
            n_liberties += 1;
        };
    };

    Group {
        value,
        n_stones,
        stones_mask,
        n_liberties,
        liberties_mask
    }
}



