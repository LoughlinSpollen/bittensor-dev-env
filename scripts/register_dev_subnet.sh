#! /usr/bin/env zsh
#! /usr/bin/expect

set -e -u
. ./scripts/env_var_dev.sh

# expect requires exports

export INTERPRETER=$(which python)
export OWNER_WALLET=local-dev-wallet-owner-0
export OWNER_HOTKEY=local-dev-hotkey-owner-0
export OWNER_COLDKEY=local-dev-coldkey-owner-0

VALIDATOR_WALLET=local-dev-wallet-validator-0
VALIDATOR_HOTKEY=local-dev-hotkey-validator-0
VALIDATOR_COLDKEY=local-dev-coldkey-validator-0

MINER_WALLET=local-dev-wallet-miner-0
MINER_HOTKEY=local-dev-hotkey-miner-0
MINER_COLDKEY=local-dev-coldkey-miner-0

export AXON_PORT=5001
export PASSWORD=Bittensor123!


create_wallet() {
    export WALLET_NAME=$1
    export WALLET_COLDKEY=$2
/usr/bin/expect << 'EOF1'
    spawn /bin/bash -c "btcli wallet new_coldkey --wallet.name $env(WALLET_NAME) \
        --wallet.coldkey $env(WALLET_COLDKEY)"
    
    set timeout -1
    expect {
        -re {Specify password for key encryption.*$} { send $env(PASSWORD)'\r'; exp_continue }
        -re {Retype your password.*$}  { send $env(PASSWORD)'\r'; exp_continue }
        eof
    }
EOF1

    export WALLET_HOTKEY=$3
/usr/bin/expect << 'EOF2' 
    spawn /bin/bash -c "btcli wallet new_hotkey --wallet.name $env(WALLET_NAME) \
        --wallet.hotkey $env(WALLET_HOTKEY)"
    set timeout -1
    expect {
        -re {already exists. Overwrite.*$} { send "y\r"; exp_continue } 
        eof
    }
EOF2
}


mint_tokens() {
    export WALLET_NAME=$1
/usr/bin/expect << 'EOF3'
    spawn /bin/bash -c "btcli wallet faucet mint --wallet.name $env(WALLET_NAME) \
        --subtensor.network $env(SUBTENSOR_NETWORK)"
    set timeout -1
    expect {
        -re {Run Faucet.*$} { send "y\r"; exp_continue } 
        -re {Enter password to unlock key.*$} { send $env(PASSWORD)'\r'; exp_continue }
        eof
    } 
EOF3
    echo "Minted tokens for $WALLET_NAME"
}


mint_subnet_registration_tokens() {
    BALANCE=$(btcli wallet balance --wallet.name $OWNER_WALLET --subtensor.network $SUBTENSOR_NETWORK \
        --no_prompt | awk -v wallet=$OWNER_WALLET '$1 == wallet {print $3}' | sed 's/,//' | sed 's/τ//' | bc) 
    REGISTRATION_COST=$(btcli subnet lock_cost --subtensor.network $SUBTENSOR_NETWORK \
        | tail -n 1 | sed 's/Subnet lock cost: τ//' | sed 's/,//' | bc)

    while [ $(echo "$BALANCE < $REGISTRATION_COST" | bc) -eq 1 ]; do
        echo "Balance: $BALANCE, Lock Cost: $REGISTRATION_COST"
        mint_tokens $OWNER_WALLET

        BALANCE=$(btcli wallet balance --wallet.name $OWNER_WALLET --subtensor.network $SUBTENSOR_NETWORK \
            --no_prompt | awk -v wallet=$OWNER_WALLET '$1 == wallet {print $3}' | sed 's/,//' | sed 's/τ//' | bc) 
        echo "New balance: $BALANCE"
    done
}


create_subnet() {

OUTPUT=$(/usr/bin/expect << 'EOF4'
    spawn /bin/bash -c "btcli subnet create --wallet.name $env(OWNER_WALLET) \
        --wallet.hotkey $env(OWNER_HOTKEY) --wallet.coldkey $env(OWNER_COLDKEY) \
        --subtensor.network $env(SUBTENSOR_NETWORK) --no_prompt"
    set timeout -1
    expect {
        -re {Enter password to unlock key.*$} { send $env(PASSWORD)'\r'; exp_continue }
        eof
    } 
EOF4
)
    # first sed is to remove formatting characters from output
    export NETUID=$(echo "$OUTPUT" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' \
        | sed -n 's/.*Registered subnetwork with netuid: \([0-9]*\).*/\1/p' | head -n 1)
    echo "Netuid: $NETUID"
}


register_wallet_on_subnet() {
    export WALLET_NAME=$1
    export WALLET_HOTKEY=$2
    export WALLET_COLDKEY=$3
/usr/bin/expect << 'EOF5'
    spawn /bin/bash -c "btcli subnet register --netuid $env(NETUID) --wallet.name $env(WALLET_NAME) \
        --wallet.hotkey $env(WALLET_HOTKEY) --wallet.coldkey $env(WALLET_COLDKEY) \
        --subtensor.network $env(SUBTENSOR_NETWORK) --no_prompt"
    set timeout -1
    expect {
        -re {Enter password to unlock key.*$} { send $env(PASSWORD)'\r'; exp_continue }
        eof
    }
EOF5
}


create_wallet $OWNER_WALLET $OWNER_COLDKEY $OWNER_HOTKEY
create_wallet $VALIDATOR_WALLET $VALIDATOR_COLDKEY $VALIDATOR_HOTKEY
create_wallet $MINER_WALLET $MINER_COLDKEY $MINER_HOTKEY
mint_tokens $VALIDATOR_WALLET
mint_tokens $MINER_WALLET
mint_subnet_registration_tokens
create_subnet
register_wallet_on_subnet $VALIDATOR_WALLET $VALIDATOR_HOTKEY $VALIDATOR_COLDKEY
register_wallet_on_subnet $MINER_WALLET $MINER_HOTKEY $MINER_COLDKEY



# registration_allowed


# btcli subnet lock_cost --subtensor.network $SUBTENSOR_NETWORK
# Bittensor Version: Current 6.8.2/Latest 6.9.3
# Please update to the latest version at your earliest convenience. Run the following command to upgrade:

# python -m pip install --upgrade bittensor
# Subnet lock cost: τ1,000.000000000














# btcli wallet faucet mint --wallet.name $WALLET --subtensor.network local


# /usr/bin/expect << 'EOF1'
#     set timeout -1
#     spawn /bin/bash -c "btcli wallet new_coldkey --wallet.name $env(WALLET) --wallet.coldkey $env(COLDKEY)"
#     expect -re {Specify password for key encryption.*$}
#     send "Bittensor123!\r" 
#     expect -re {Retype your password.*$}
#     send "Bittensor123!\r"
#     expect eof    
# EOF1



# echo "waiting for the node to start"
# sleep 5
# echo "creating wallet"
# create_wallet
# echo "minting tokens"
# mint_tokens
# echo "registering subnet"
# register_subnet





# btcli subnet register --netuid $NETUID --subtensor.network local
# btcli subnet register --wallet.name $WALLET --wallet.hotkey $HOTKEY --wallet.coldkey $COLDKEY --netuid $NETUID --subtensor.network local


# python ./neurons/miner.py --name $MINOR_NAME \
#     --interpreter $INTERPRETER \
#     -- --netuid $NETUID \
#     --subtensor.network $SUBTENSOR_NETWORK \  
#     --wallet.name $WALLET \
#     --wallet.hotkey $HOTKEY \
#     --wallet.coldkey $COLDKEY \
#     --axon.port $AXON_PORT \ 
#     --logging.debug \
#     --miner.blacklist.force_validator_permit \
#     --auto_update