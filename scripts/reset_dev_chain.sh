#! /usr/bin/env zsh
set -e -u
. ./scripts/env_var_dev.sh

rm -rf $CHAIN_PATH
echo "Chain removed"
rm -rf $NODE_1_INSTALL_PATH
echo "Node 1 removed"
rm -rf $NODE_2_INSTALL_PATH
echo "Node 2 removed"

rm -rf ~/.bittensor/wallets/
echo "Wallets removed"