#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')

# sozo execute --world <WORLD_ADDRESS> --account-address <ACCOUNT_ADDRESS> <CONTRACT> <ENTRYPOINT>
sozo execute -v \
    --world $WORLD_ADDRESS \
    --profile two \
    starkgo::systems::actions::actions join_game -c 2 --wait --receipt
