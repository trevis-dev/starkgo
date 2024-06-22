use core::array::ArrayTrait;
use starkgo::models::{game::Player, board::{Board, Position, GRID_SIZE, pow2_128, _get_value}};

struct Group {
    value: u8,
    n_stones: usize,
    stones_mask: Array<usize>,
    n_liberties: usize,
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

struct MoveCapture {
    stones_mask: u128,
    black: u32,
    white: u32,
}


fn remove_dead_stones(board: @u256, x: usize, y:usize, value: u8) -> Option<MoveCapture> {
    let mut positions_checked: Felt252Dict<bool> = Default::default();
    let mut positions_to_check = get_neighbors(x, y);
    positions_to_check.append((x, y)); // Make sure we go through it after the other if does not belong to any group
    let mut n_positions_to_check = positions_to_check.len();
    let mut n_positions_checked: usize = 0;
    let mut stones_captured = 0;
    let mut capture: Array<usize> = array![];
    let mut capture_own = false;
    let mut capture_other = false;
    while n_positions_checked < n_positions_to_check {
        let (new_x, new_y) = *positions_to_check.at(n_positions_checked);
        let new_position_int = position_to_int(new_x, new_y);
        n_positions_checked += 1;
        if positions_checked.get(new_position_int.into()) == false {
            positions_checked.insert(new_position_int.into(), true);
            let other_value = _get_value(board, new_x, new_y);
            if other_value != 0 {
                let mut group = get_group_mask_and_liberties(board, new_x, new_y, other_value);
                if group.n_liberties == 0 {
                    if group.value == value {
                        capture_own = true;
                    } else {
                        stones_captured += group.n_stones;
                        capture_other = true;
                    };
                };
                while let Option::Some(stone_position_int) = group.stones_mask.pop_front() {
                    positions_checked.insert(stone_position_int.into(), true);
                    if (group.n_liberties == 0 && group.value != value) {
                        capture.append(stone_position_int);
                    };
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
        let mut stones_mask: u128 = 0;
        while let Option::Some(stone) = capture.pop_front() {
            stones_mask += pow2_128(stone);
        };
        Option::Some(MoveCapture {
            stones_mask,
            black,
            white,
        })

    } else {
        Option::None
    }
}


fn get_group_mask_and_liberties(board: @u256, x: usize, y:usize, value: u8) -> Group {
    let stone_mask = position_to_int(x, y);
    let mut stones_mask: Array<usize> = array![stone_mask];
    let mut positions_checked: Felt252Dict<bool> = Default::default();  // don't got there twice
    positions_checked.insert(stone_mask.into(), true);
    let mut n_positions_checked: usize = 0;  // As the one above won't be in the list
    
    let mut n_stones: usize = 1;

    let mut n_liberties: usize = 0;
    
    let mut known_positions: Felt252Dict<bool> = Default::default();
    known_positions.insert(stone_mask.into(), true);
    
    let mut positions_to_check = get_neighbors(x, y);
    let positions_to_check_copy = positions_to_check.clone();
    let mut n_positions_to_check: usize = positions_to_check.len();
    let mut idx: usize = 0;
    while idx < n_positions_to_check{
        let (n_x, n_y) = *positions_to_check_copy.at(idx);
        known_positions.insert(position_to_int(n_x, n_y).into(), true);
        idx+=1
    };

    while n_positions_checked < n_positions_to_check {
        let (new_x, new_y) = *positions_to_check.at(n_positions_checked);
        let new_position_mask = position_to_int(new_x, new_y);
        n_positions_checked += 1;
        positions_checked.insert(new_position_mask.into(), true);
        let other_value = _get_value(board, new_x, new_y);
        if other_value == value {
            n_stones += 1;
            stones_mask.append(new_position_mask);
            let mut potential_positions_to_check = get_neighbors(new_x, new_y);
            while let Option::Some(pos) = potential_positions_to_check.pop_front() {
                let (pos_x, pos_y) = pos;
                let pos_int = position_to_int(pos_x, pos_y);
                if known_positions.get(pos_int.into()) == false {
                    known_positions.insert(pos_int.into(), true);
                    positions_to_check.append(pos);
                    n_positions_to_check += 1
                };
            };
        } else if other_value == 0 {
            n_liberties += 1;
        };
    };

    Group {
        value,
        n_stones,
        stones_mask,
        n_liberties,
    }
}
