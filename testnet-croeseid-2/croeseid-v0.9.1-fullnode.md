# Running a fullnode of Croeseid testnet

## Introduction

Since there was a network upgrade of `testnet-croeseid-2`, If you would like to build a fullnode will complete blockchain data from scratch:

1. Begin with the older version [v0.8.1-croeseid](https://github.com/crypto-org-chain/chain-main/releases/tag/v0.8.1-croeseid) of `chain-maind`;
1. Let it sync to block height `905532`, which is the block height of the upgrade happened;
1. The `chain-maind` should stop and ask you to upgrade;
1. You can then restart the node with [v0.9.1-croeseid](https://github.com/crypto-org-chain/chain-main/releases/tag/v0.9.1-croeseid) and let it synced to the latest block.


## Detailed instructions

### Pre-requisites

#### Supported OS

We officially support macOS, Windows and Linux only. Other platforms may work but there is no guarantee. We will extend our support to other platforms after we have stabilized our current architecture.

### Prepare your machine

To run Crypto.org Chain nodes in the testnet, you will need a machine with the following minimum requirements:

- Dual-core, x86_64 architecture processor;
- 4GB RAM;
- 100GB of storage space.

For Crypto.org Chain mainnet in the future, you will need a machine with the following minimum requirements:

- 4-core, x86_64 architecture processor;
- 16GB RAM;
- 1TB of storage space.

## Step 1. Get the Crypto.org Chain binary (`v0.8.1-croeseid`)

To simplify the following step, we will be using **Linux** for illustration. Binary for
[Mac](https://github.com/crypto-com/chain-main/releases/download/v0.8.1-croeseid/chain-main_0.8.1-croeseid_Darwin_x86_64.tar.gz) and [Windows](https://github.com/crypto-com/chain-main/releases/download/v0.8.1-croeseid/chain-main_0.8.1-croeseid_Windows_x86_64.zip) are also available.

- To install Crypto.org Chain released binaries from github:

  ```bash
  $ curl -LOJ https://github.com/crypto-com/chain-main/releases/download/v0.8.1-croeseid/chain-main_0.8.1-croeseid_Linux_x86_64.tar.gz
  $ tar -zxvf chain-main_0.8.1-croeseid_Linux_x86_64.tar.gz
  ```


## Step 2. Configure `chain-maind`

Before kick-starting your node, we will have to configure your node so that it connects to the Croeseid testnet:

### Step 2-1 Initialize `chain-maind`

- First of all, you can initialize chain-maind by:

  ```bash
    $ ./chain-maind init [moniker] --chain-id testnet-croeseid-2
  ```

  This `moniker` will be the displayed id of your node when connected to Crypto.org Chain network.
  When providing the moniker value, make sure you drop the square brackets since they are not needed.
  The example below shows how to initialize a node named `pegasus-node` :

  ```bash
    $ ./chain-maind init pegasus-node --chain-id testnet-croeseid-2
  ```

  **NOTE**

  - Depending on your chain-maind home setting, the chain-maind configuration will be initialized to that home directory. To simply the following steps, we will use the default chain-maind home directory `~/.chain-maind/` for illustration.
  - You can also put the `chain-maind` to your binary path and run it by `chain-maind`


### Step 2-2 Configurate chain-maind

- Download and replace the Croeseid Testnet `genesis.json` by:

  ```bash
  $ curl https://raw.githubusercontent.com/crypto-com/testnets/main/testnet-croeseid-2/genesis.json > ~/.chain-maind/config/genesis.json
  ```

- Verify sha256sum checksum of the downloaded `genesis.json`. You should see `OK!` if the sha256sum checksum matches.

  ```bash
  $ if [[ $(sha256sum ~/.chain-maind/config/genesis.json | awk '{print $1}') = "af7c9828806da4945b1b41d434711ca233c89aedb5030cf8d9ce2d7cd46a948e" ]]; then echo "OK"; else echo "MISMATCHED"; fi;

  OK!
  ```

- In `~/.chain-maind/config/app.toml`, update minimum gas price to avoid [transaction spamming](https://github.com/cosmos/cosmos-sdk/issues/4527)

  ```bash
  $ sed -i.bak -E 's#^(minimum-gas-prices[[:space:]]+=[[:space:]]+)""$#\1"0.025basetcro"#' ~/.chain-maind/config/app.toml
  ```

- For network configuration, in `~/.chain-maind/config/config.toml`, please modify the configurations of `persistent_peers` and `create_empty_blocks_interval` by:

  ```bash
  $ sed -i.bak -E 's#^(persistent_peers[[:space:]]+=[[:space:]]+).*$#\1"b2c6657096aa30c5fafa5bd8ced48ea8dbd2b003@52.76.189.200:26656,ef472367307808b242a0d3f662d802431ed23063@175.41.186.255:26656,d3d2139a61c2a841545e78ff0e0cd03094a5197d@18.136.230.70:26656"# ; s#^(create_empty_blocks_interval[[:space:]]+=[[:space:]]+).*$#\1"5s"#' ~/.chain-maind/config/config.toml
  ```


## Step 3. Run everything


Once the `chain-maind` has been configured, we are ready to start the node and sync the blockchain data:

- Start chain-maind, e.g.:

```bash
  $ ./chain-maind start
```

It should begin fetching blocks from the other peers. 

For example, one can check the current block height by querying the public full node by:

```bash
curl -s https://testnet-croeseid.crypto.org:26657/commit | jq "{height: .result.signed_header.header.height}"
```



## Step 4. Restart `chain-maind` with  `v0.9.1-croeseid`


Once it has been synced to block height `905532`. The `chain-maind` should stop and ask you to upgrade to `v0.9.1-croeseid`.

- To install Crypto.org Chain released binaries `v0.9.1-croeseid` from github:

  ```bash
  $ curl -LOJ https://github.com/crypto-org-chain/chain-main/releases/download/v0.9.1-croeseid/chain-main_0.9.1-croeseid_Linux_x86_64.tar.gz
  $ tar -zxvf chain-main_0.9.1-croeseid_Linux_x86_64.tar.gz
  ```

**Note**: Binary for [Mac](https://github.com/crypto-org-chain/chain-main/releases/download/v0.9.1-croeseid/chain-main_0.9.1-croeseid_Darwin_x86_64.tar.gz) and [Windows](https://github.com/crypto-org-chain/chain-main/releases/download/v0.9.1-croeseid/chain-main_0.9.1-croeseid_Windows_x86_64.zip) are also available.

Once it has been done, you can check the version of your `chain-maind` by:

```bash
$ ./chain-maind version
0.9.1-croeseid
```
Afterwards, you can restart the node with the `v0.9.1-croeseid` binary by:

```bash
./chain-maind start
```


It should begin fetching blocks from the other peers. Please wait until it is fully synced.