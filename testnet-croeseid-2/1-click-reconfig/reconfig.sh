#!/usr/bin/env bash

set -e

download_genesis()
{
    echo_s "💾 Downloading $NETWORK genesis"
    curl -sS $NETWORK_URL/$NETWORK/genesis.json -o $CM_GENESIS
}
download_binary()
{
    echo_s "💾 Downloading $NETWORK binary"
    TEMP_DIR="$(mktemp -d)"
    curl -LJ $(curl -sS $NETWORK_URL/testnet.json | jq -r ".\"$NETWORK\".binary.linux") -o $TEMP_DIR/chain-maind.tar.gz
    tar -xzf $TEMP_DIR/chain-maind.tar.gz -C $TEMP_DIR
    mv $TEMP_DIR/chain-maind $CM_BINARY
    rm -rf $TEMP_DIR
}
DaemonReloadFunction()
{
    sudo systemctl daemon-reload
}
EnableFunction()
{
    DaemonReloadFunction
    sudo systemctl enable chain-maind.service tmkms.service
}
StopService()
{
    # Stop service
    echo_s "Stopping chain-maind tmkms service"
    sudo systemctl stop chain-maind.service tmkms.service
}
# Regenerate tmkms signing key and restart tmkms service
RegenerateTMKMS()
{
    echo_s "🔄 Regenerate tmkms consensus-ed25519 key 🔑"
    /chain/bin/tmkms softsign keygen -t consensus $TMKMS_KEY
    rm -rf /tmp/.tmkms
    echo_s "🔄 Regenerate tmkms validator secret key 🔑"
    /chain/bin/tmkms init /tmp/.tmkms > /dev/null
    cp /tmp/.tmkms/secrets/kms-identity.key $TMKMS_SECRET
    rm -rf /tmp/.tmkms
    echo_s "Restart tmkms service"
    sudo systemctl restart tmkms.service
    ShowTMKMSKey
}
ShowTMKMSKey()
{
    echo_s "🕑 Waiting for tmkms to run"
    sleep 5
    echo_s "✅ Please keep consensus public key for node join if it is validator or find it again in /chain/log/tmkms/tmkms.log. It will show again when restart tmkms in log\n"
    CONSENSUS_PUBLIC_KEY=$(cat /chain/log/tmkms/tmkms.log | grep "consensus Ed25519 key" | tail -1 | awk '{print $NF}')
    echo_s "Consensus public key for node join: \033[32m$CONSENSUS_PUBLIC_KEY\033[0m\n"
}
# Regenerate node_key.json
RegenerateNodeKeyJSON()
{
    echo_s "Generate and replace node_key in $NODE_KEY_PATH\n"
    rm -rf /tmp/.chain-maind
    $CM_BINARY init tmp --home /tmp/.chain-maind > /dev/null 2>&1
    cp /tmp/.chain-maind/config/node_key.json $NODE_KEY_PATH
    rm -rf /tmp/.chain-maind
    ShowNodeKeyInfo
}
# print node_key and node_id
ShowNodeKeyInfo()
{
    NODE_ID=$($CM_BINARY tendermint show-node-id --home $CM_HOME)
    NODE_KEY=$(cat $NODE_KEY_PATH | jq .priv_key.value -r)
    echo_s "You may want to save node_id and node_key for later use\n"
    echo_s "node_id: \033[32m$NODE_ID\033[0m\n"
    echo_s "node_key: \033[32m$NODE_KEY\033[0m\n"
}
# allow gossip this ip
AllowGossip()
{
    # find IP
    IP=$(curl -s http://checkip.amazonaws.com)
    if [[ -z "$IP" ]] ; then
        read -p 'What is the public IP of this server?: ' IP
    fi
    echo_s "✅ Added public IP to external_address in chain-maind config.toml for p2p gossip\n"
    sed -i "s/^\(external_address\s*=\s*\).*\$/\1\"$IP:26656\"/" $CM_HOME/config/config.toml
}
EnableStateSync()
{
    RPC_SERVERS=$(curl -sS $NETWORK_URL/testnet.json | jq -r ".\"$NETWORK\".endpoint.rpc")
    LASTEST_HEIGHT=$(curl -s $RPC_SERVERS/block | jq -r .result.block.header.height)
    BLOCK_HEIGHT=$((LASTEST_HEIGHT - 1000))
    TRUST_HASH=$(curl -s "$RPC_SERVERS/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
    sed -i "s/^\(seeds\s*=\s*\).*\$/\1\"\"/" $CM_HOME/config/config.toml
    sed -i "s/^\(persistent_peers\s*=\s*\).*\$/\1\"$SEEDS\"/" $CM_HOME/config/config.toml
    sed -i "s/^\(trust_height\s*=\s*\).*\$/\1$BLOCK_HEIGHT/" $CM_HOME/config/config.toml
    sed -i "s/^\(trust_hash\s*=\s*\).*\$/\1\"$TRUST_HASH\"/" $CM_HOME/config/config.toml
    sed -i "s/^\(enable\s*=\s*\).*\$/\1true/" $CM_HOME/config/config.toml
    sed -i "s|^\(rpc_servers\s*=\s*\).*\$|\1\"$RPC_SERVERS,$RPC_SERVERS\"|" $CM_HOME/config/config.toml

}
DisableStateSync()
{
    sed -i "s/^\(enable\s*=\s*\).*\$/\1false/" $CM_HOME/config/config.toml
}
shopt -s extglob
checkout_network()
{
    mapfile -t arr < <(curl -sS $NETWORK_URL/testnet.json | jq -r 'keys[]')

    echo_s "You can select the following networks to join"
    for i in "${!arr[@]}"; do
        printf '\t%s. %s\n' "$i" "${arr[i]}"
    done

    read -p "Please choose the network to join by index (0/1/...): " index
    case $index in
        +([0-9]))

        if [[ $index -gt $((${#arr[@]} - 1)) ]]; then
                    echo_s "Larger than the max index"
            exit 1
        fi
        NETWORK=${arr[index]}
        echo_s "The selected network is $NETWORK"
        GENESIS_TARGET_SHA256=$(curl -sS $NETWORK_URL/testnet.json | jq -r ".\"$NETWORK\".genesis_sha256sum")
        if [[ ! -f "$CM_GENESIS" ]] || (! echo "$GENESIS_TARGET_SHA256 $CM_GENESIS" | sha256sum -c --status --quiet - > /dev/null 2>&1) ; then
            echo_s "The genesis does not exit or the sha256sum does not match the target one. Download the target genesis from github."
            download_genesis
        fi
        CM_DESIRED_VERSION=$(curl -sS $NETWORK_URL/testnet.json | jq -r ".\"$NETWORK\".version")
        if [[ ! -f "$CM_BINARY" ]] || [[ $($CM_BINARY version 2>&1) != $CM_DESIRED_VERSION ]]; then
            echo_s "The binary does not exist or the version does not match the target version. Download the target version binary from github release."
            download_binary
        fi
        ;;
        *)
        echo_s "No match"
        exit 1
        ;;
    esac
}
echo_s()
{
    echo -e $1
}

if ! [ -x "$(command -v jq)" ]; then
    echo 'jq not installed! Installing jq' >&2
    sudo apt update
    sudo apt install jq -y
fi

if [ "$(whoami)" != "crypto" ]; then
    echo_s "Please run with \"\033[32msudo -u crypto $0\033[0m\"" >&2
    exit 1
fi

# Enable systemd service for chain-maind and tmkms
EnableFunction

# Select network
NETWORK_URL="https://raw.githubusercontent.com/crypto-com/testnets/main"
CM_HOME="/chain/.chain-maind"
CM_BINARY="/chain/bin/chain-maind"
CM_GENESIS="$CM_HOME/config/genesis.json"
checkout_network
echo 'PATH=$PATH:/chain/bin' | sudo tee /etc/profile.d/custom-path.sh > /dev/null

# Remove old data, generate and replace node_key
echo_s "Reset chain-maind and remove data if any"
if [[ -d "$CM_HOME/data" ]]; then
    read -p '❗️ Enter (Y/N) to confirm to delete any old data: ' yn
    case $yn in
        [Yy]* ) StopService; $CM_BINARY unsafe-reset-all --home $CM_HOME;;
        * ) echo_s "Not delete and exit\n"; exit 0;;
    esac
fi

# Config tmkms and regenerate signing key
TMKMS_KEY="/chain/.tmkms/secrets/consensus-ed25519.key"
TMKMS_SECRET="/chain/.tmkms/secrets/kms-identity.key"
TMKMS_CONFIG="/chain/.tmkms/tmkms.toml"
sed -i "s/^\(id\s*=\s*\).*\$/\1\"$NETWORK\"/;s/^\(chain_id\s*=\s*\).*\$/\1\"$NETWORK\"/;s/^\(chain_ids\s*=\s*\).*\$/\1[\"$NETWORK\"]/" $TMKMS_CONFIG
if [[ -f "$TMKMS_KEY" ]]; then
    read -p "❗️ $TMKMS_KEY already exists! Do you want to override old key? (Y/N): " yn
    case $yn in
        [Yy]* ) RegenerateTMKMS;;
        * ) echo_s "Keep original key in $TMKMS_KEY and Restart tmkms service\n"; sudo systemctl restart tmkms.service; ShowTMKMSKey;;
    esac
else
    RegenerateTMKMS
fi

# Config .chain-maind/config/config.toml
echo_s "Replace moniker in $CM_HOME/config/config.toml"
echo_s "Moniker is display name for tendermint p2p\n"
while true
do
    read -p 'moniker: ' MONIKER

    if [[ -n "$MONIKER" ]] ; then
        sed -i "s/^\(moniker\s*=\s*\).*\$/\1\"$MONIKER\"/" $CM_HOME/config/config.toml
        SEEDS=$(curl -sS $NETWORK_URL/testnet.json | jq -r ".\"$NETWORK\".seeds")
        sed -i "s/^\(seeds\s*=\s*\).*\$/\1\"$SEEDS\"/" $CM_HOME/config/config.toml
        sed -i "s/^\(\s*\[\"chain_id\",\s*\).*\$/\1\"$NETWORK\"],/" $CM_HOME/config/app.toml
        read -p "Do you want to enable state-sync? (Y/N): " yn
        case $yn in
            [Yy]* ) EnableStateSync;;
            * ) DisableStateSync;;
        esac

        read -p "Do you want to add the public IP of this node for p2p gossip? (Y/N): " yn
        case $yn in
            [Yy]* ) AllowGossip;;
            * )
                echo_s "WIll keep 'external_address value' empty\n";
                sed -i "s/^\(external_address\s*=\s*\).*\$/\1\"\"/" $CM_HOME/config/config.toml;;
        esac
        break
    else
        echo_s "moniker is not set. Try again!\n"
    fi

done

# generate new node id and node key
NODE_KEY_PATH="$CM_HOME/config/node_key.json"
if [[ -f "$NODE_KEY_PATH" ]]; then
    read -p "$NODE_KEY_PATH already exists! Do you want to override old node_key.json? (Y/N): " yn
    case $yn in
        [Yy]* ) RegenerateNodeKeyJSON;;
        * ) echo_s "Keep original node_key.json in $NODE_KEY_PATH\n"; ShowNodeKeyInfo;;
    esac
else
    RegenerateNodeKeyJSON
fi

# Restart service
echo_s "👏🏻 Restarting chain-maind service\n"
sudo systemctl restart chain-maind.service
sudo systemctl restart rsyslog

echo_s "👀 View the log by \"\033[34mjournalctl -u chain-maind.service -f\033[0m\" or find in /chain/log/chain-maind/chain-maind.log"