#! /usr/bin/env zsh

set -e -u

. ./scripts/env_var_dev.sh

start_nodes() {
    CURRENT_DIR=$(pwd)
    cd ../subtensor

    if [ ! -d "$CHAIN_PATH" ]; then
        mkdir $CHAIN_PATH
    fi

    if [ ! -d "$NODE_1_INSTALL_PATH" ]; then
        mkdir -p $NODE_1_INSTALL_PATH
    fi

    if [ ! -d "$NODE_2_INSTALL_PATH" ]; then
        mkdir -p $NODE_2_INSTALL_PATH
    fi

    if [ -f "$CHAIN" ]; then
        ./target/release/node-subtensor purge-chain -y --base-path $NODE_1_INSTALL_PATH --chain=$CHAIN
        ./target/release/node-subtensor purge-chain -y --base-path $NODE_2_INSTALL_PATH --chain=$CHAIN
    else
        ./target/release/node-subtensor build-spec --disable-default-bootnode --raw --chain $SUBTENSOR_NETWORK > $CHAIN
    fi

    # Alice and Bob nodes are hardcoded for local network
    # https://github.com/opentensor/subtensor/blob/101ce8827faec82389f3bcdd5252ebe3d72f71ab/node/src/chain_spec.rs#L392
    node_1_start=(
        ./target/release/node-subtensor
        --base-path $NODE_1_INSTALL_PATH
        --chain=$CHAIN
        --alice
        --port $NODE_1_PORT
        --ws-port $NODE_1_WS_PORT
        --rpc-port $NODE_1_RPC_PORT
        --validator
        --rpc-cors=all
        --allow-private-ipv4
        --discover-local
    )

    node_2_start=(
        ./target/release/node-subtensor
        --base-path $NODE_2_INSTALL_PATH
        --chain=$CHAIN
        --bob
        --port $NODE_2_PORT
        --ws-port $NODE_2_WS_PORT
        --rpc-port $NODE_2_RPC_PORT
        --validator
        --allow-private-ipv4
        --discover-local
    )   
    
    (trap 'kill 0' SIGINT; ("${node_1_start[@]}" 2>&1) & ("${node_2_start[@]}" 2>&1))

    cd $CURRENT_DIR
}

start_nodes