#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')

# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>
sozo execute --world $WORLD_ADDRESS starkgo::systems::actions::actions create_game -c 1 --wait
sozo execute --world $WORLD_ADDRESS starkgo::systems::actions::actions create_game -c 2 --wait
sozo execute -v \
    --profile two \
    --world $WORLD_ADDRESS \
    starkgo::systems::actions::actions join_game -c 1 --wait
sozo execute -v \
    --world $WORLD_ADDRESS \
    --profile two \
    starkgo::systems::actions::actions join_game -c 2 --wait 
sozo execute --world $WORLD_ADDRESS starkgo::systems::actions::actions set_black -c 1,1 --wait
sozo execute --world $WORLD_ADDRESS starkgo::systems::actions::actions set_black -c 2,0 --wait
sozo execute \
    --profile two \
    --world $WORLD_ADDRESS \
    starkgo::systems::actions::actions \
    set_black -c 1,1 --wait
sozo execute \
    --profile two \
    --world $WORLD_ADDRESS \
    starkgo::systems::actions::actions set_black -c 2,0 --wait
