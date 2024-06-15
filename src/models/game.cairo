use starknet::ContractAddress;
use starkgo::models::board::{Board, Player};

# [derive(Serde, Copy, Drop, Introspect, PartialEq, Print)]
enum GameState {
    Inexistent,
    Created,
    Joined,
    Ongoing,
    Finished,
}


#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Games {
    #[key]
    game_id: felt252,
    state: GameState,
    controller: Option<ContractAddress>,
    opponent: Option<ContractAddress>,
    controller_has_black: bool,
    board: Board,
    new_turn_player: Player
}
