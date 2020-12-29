# testnet-croeseid-2

- chain-maind version: [v0.8.0-rc1+](https://github.com/crypto-com/chain-main/releases)
- Seeds:

```
b2c6657096aa30c5fafa5bd8ced48ea8dbd2b003@52.76.189.200:26656
ef472367307808b242a0d3f662d802431ed23063@175.41.186.255:26656
d3d2139a61c2a841545e78ff0e0cd03094a5197d@18.136.230.70:26656
```

# Network upgrade guide:

This is a guide for existing validator to upgrade from `testnet-croeseid-1` (v0.7._) to `testnet-croeseid-2` (v0.8._): 

To simply the following steps, we will be using **Linux** for illustration. Binary for
[Mac](https://github.com/crypto-com/chain-main/releases/download/v0.8.0-rc1/chain-main_0.8.0-rc1_Darwin_x86_64.tar.gz) and [Windows](https://github.com/crypto-com/chain-main/releases/download/v0.8.0-rc1/chain-main_0.8.0-rc1_Windows_x86_64.zip) are also available.

### Step 1
Stop the `chain-maind` and download the released binaries from github:

  ```bash
  $ curl -LOJ https://github.com/crypto-com/chain-main/releases/download/v0.8.0-rc1/chain-main_0.8.0-rc1_Linux_x86_64.tar.gz
  $ tar -zxvf chain-main_0.8.0-rc1_Linux_x86_64.tar.gz
  ```

### Step 2
Using the new binary, remove the old blockchain data by running

```bash
$ ./chain-maind unsafe-reset-all

INF Removed existing address book   file=/Users/.chain-maind/config/addrbook.json
INF Removed all blockchain history  dir=/Users/.chain-maind/data
INF Reset private validator file to genesis state keyFile=/Users/.chain-maind/config/priv_validator_key.json stateFile=/Users/.chain-maind/data/priv_validator_state.json
```


### Step 3 Configure `chain-maind`

- Download the and replace the Croseid Testnet `genesis.json` by:

  ```bash
  $ curl https://raw.githubusercontent.com/crypto-com/testnets/main/testnet-croeseid-2/genesis.json > ~/.chain-maind/config/genesis.json
  ```

- Verify sha256sum checksum of the downloaded `genesis.json`. You should see `OK!` if the sha256sum checksum matches.

  ```bash
  $ if [[ $(sha256sum ~/.chain-maind/config/genesis.json | awk '{print $1}') = "af7c9828806da4945b1b41d434711ca233c89aedb5030cf8d9ce2d7cd46a948e" ]]; then echo "OK"; else echo "MISMATCHED"; fi;

  OK!
  ```

- For Cosmos configuration, in `~/.chain-maind/config/app.toml`, update minimum gas price to avoid [transaction spamming](https://github.com/cosmos/cosmos-sdk/issues/4527)

  ```bash
  $ sed -i.bak -E 's#^(minimum-gas-prices[[:space:]]+=[[:space:]]+)""$#\1"0.025basetcro"#' ~/.chain-maind/config/app.toml
  ```

- For network configuration, in `~/.chain-maind/config/config.toml`, please modify the configurations of `seeds` and `create_empty_blocks_interval` by:

  ```bash
  $ sed -i.bak -E 's#^(seeds[[:space:]]+=[[:space:]]+).*$#\1"b2c6657096aa30c5fafa5bd8ced48ea8dbd2b003@52.76.189.200:26656,ef472367307808b242a0d3f662d802431ed23063@175.41.186.255:26656,d3d2139a61c2a841545e78ff0e0cd03094a5197d@18.136.230.70:26656"# ; s#^(create_empty_blocks_interval[[:space:]]+=[[:space:]]+).*$#\1"5s"#' ~/.chain-maind/config/config.toml
  ```
#### Step 3.5 (Optional) Configure `STATE-SYNC`

[STATE-SYNC](https://docs.tendermint.com/master/tendermint-core/state-sync.html) is supported in our testnet! 🎉

With state sync your node will download data related to the head or near the head of the chain and verify the data. This leads to drastically shorter times for joining a network for validator.

However, you should keep in mind that the block before state-sync `trust height` will not be queryable. So if you want to run a full node, better not use state-sync feature to ensure your node has every data on the blockchain network.
For validator, it will be amazingly fast to sync the near head of the chain and join the network.

Follow the below optional steps to enable state-sync.


- (**Optional**) For state-sync configuration, in `~/.chain-maind/config/config.toml`, please modify the configurations of [statesync] `enable`, `rpc_servers`, `trust_height` and `trust_hash` by:

  ```bash
  $ LASTEST_HEIGHT=$(curl -s https://testnet-croeseid.crypto.com:26657/block | jq -r .result.block.header.height); \
  BLOCK_HEIGHT=$((LASTEST_HEIGHT - 1000)); \
  TRUST_HASH=$(curl -s "https://testnet-croeseid.crypto.com:26657/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

  $ sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
  s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"https://testnet-croeseid.crypto.com:26657,https://testnet-croeseid.crypto.com:26657\"| ; \
  s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
  s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" ~/.chain-maind/config/config.toml
  ```

### Step 4 Run everything

### Step 4-1. Obtain test token

Your previous keys are still there and simply list them by running

```bash
./chain-maind keys list
```
If you have obtained the CRO testnet token before in the previous testnet, kindly lookup and check that if your `tcro...` address is contained in the new genesis file https://raw.githubusercontent.com/crypto-com/testnets/main/testnet-croeseid-2/genesis.json. 

- **If thats the case**, It implies that the funds has already been allocated to you in the new testnet;
- **If not**, you can simply send a message on [Discord](https://discord.gg/pahqHz26q4), stating who you are and your `tcro.....` address.

You can also check you balance on the new testnet by:

```bash
$ ./chain-maind q bank balances <YOUR_TCRO_ADDRESS> --node https://testnet-croeseid.crypto.com:26657
```
### Step 4-2. Run everything

Once the `chain-maind` has been configured, we are ready to start the node and sync the blockchain data:

- Start chain-maind, e.g.:

```bash
  $ ./chain-maind start
```
Sit back and wait for the syncing process. You can check the latest block height by 

```bash
$ curl -s https://testnet-croeseid.crypto.com:26657/commit | jq "{height: .result.signed_header.header.height}" 
```

Once it's fully synced, we are ready to join the network as a validator: 

### Step 4-3. Obtain the a validator public key and join the network

- You can obtain your validator public key by:

    ```bash
    $ ./chain-maind tendermint show-validator
    ```

    The public key should begin with the `tcrocnclconspub1` prefix, e.g. `tcrocnclconspub1zcjduepq6jgw5hz44jnmlhnx93dawqx6kwzhp96w5pqsxwryp8nrr5vldmsqu3838p`.


- We are now ready to send a `create-validator` transaction and join the network, for example:

    ```
    $ ./chain-maind tx staking create-validator \
    --from=[name_of_your_key] \
    --amount=100000tcro \
    --pubkey=[tcrocnclconspub...]  \
    --moniker="[The_id_of_your_node]" \
    --security-contact="[security contact email/contact method]" \
    --chain-id="testnet-croeseid-2" \
    --commission-rate="0.10" \
    --commission-max-rate="0.20" \
    --commission-max-change-rate="0.01" \
    --min-self-delegation="1" \
    --gas 80000000 \
    --gas-prices 0.1basetcro

    {"body":{"messages":[{"@type":"/cosmos.staking.v1beta1.MsgCreateValidator"...}
    confirm transaction before signing and broadcasting [y/N]: y
    ```

    You will be required to insert the following:

    - `--from`: The `trco...` address that holds your funds;
    - `--pubkey`: The validator public key( See Step [3-3](#step-3-3-obtain-the-a-validator-public-key) above ) with **tcrocnclconspub** as the prefix;
    - `--moniker`: A moniker (name) for your validator node;
    - `--security-contact`: Security contact email/contact method.

    Once the `create-validator` transaction completes, you can check if your validator has been added to the validator set:

    ```bash
    $ ./chain-maind tendermint show-validator
    ## [tcrocnclconspub... consensus public key] ##
    $ ./chain-maind query tendermint-validator-set | grep -c [tcrocnclconspub...]
    ## 1 = Yes; 0 = Not yet added ##
    ````