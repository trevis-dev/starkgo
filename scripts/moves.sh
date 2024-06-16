#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')

# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>
sozo execute --world $WORLD_ADDRESS starkgo::systems::actions::actions move -c 1,0,4,6,0,0 --wait
sozo execute --profile two --world $WORLD_ADDRESS starkgo::systems::actions::actions move -c 1,0,5,5,0,0 --wait
sozo execute --world $WORLD_ADDRESS starkgo::systems::actions::actions move -c 1,0,5,6,0,0 --wait
