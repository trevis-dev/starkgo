#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')

sozo execute -v \
    --profile two \
    --world $WORLD_ADDRESS \
    starkgo::systems::actions::actions \
    set_black \
    -c 1,1 \
    --wait --receipt
