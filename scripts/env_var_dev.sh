#! /usr/bin/env sh

export SUBTENSOR_NETWORK=local
export NODE_1_INSTALL_PATH=/tmp/bittensor/node/1
export NODE_2_INSTALL_PATH=/tmp/bittensor/node/2
export NODE_1_PORT=30334
export NODE_2_PORT=30335
export NODE_1_WS_PORT=9944
export NODE_2_WS_PORT=9943
export NODE_1_RPC_PORT=9933
export NODE_2_RPC_PORT=9932

export CHAIN_PATH=chain
export CHAIN="$CHAIN_PATH/$SUBTENSOR_NETWORK.json"

