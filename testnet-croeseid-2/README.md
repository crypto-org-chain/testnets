# testnet-croeseid-2

- chain-maind version: [v0.9.1-croeseid](https://github.com/crypto-org-chain/chain-main/releases)
- Seeds:

```
b2c6657096aa30c5fafa5bd8ced48ea8dbd2b003@52.76.189.200:26656
ef472367307808b242a0d3f662d802431ed23063@175.41.186.255:26656
d3d2139a61c2a841545e78ff0e0cd03094a5197d@18.136.230.70:26656
```

# Network upgrade guide:

This is a guide for existing validator to upgrade from `v0.8.1-croeseid` to `v0.9.1-croeseid`:

To simply the following steps, we will be using **Linux** for illustration. Binary for
[Mac](https://github.com/crypto-org-chain/chain-main/releases/download/v0.9.1-croeseid/chain-main_0.9.1-croeseid_Darwin_x86_64.tar.gz) and [Windows](https://github.com/crypto-org-chain/chain-main/releases/download/v0.9.1-croeseid/chain-main_0.9.1-croeseid_Windows_x86_64.zip) are also available.

## Step 1 - Get the new binary

After 2021-03-01 09:00:00UTC, the node running `v0.8.1-croeseid` should stop and all you have to to is to restart your node with the new version of `chain-maind` binary -  `v0.9.1-croeseid` 


- Stop the `chain-maind` and download the released binaries from github:

```bash
$ curl -LOJ https://github.com/crypto-org-chain/chain-main/releases/download/v0.9.1-croeseid/chain-main_0.9.1-croeseid_Linux_x86_64.tar.gz
$ tar -zxvf chain-main_0.9.1-croeseid_Linux_x86_64.tar.gz
```

Remarks: If you have stated `chain-maind` with systemd service, remember to stop it by `sudo systemctl stop chain-maind`

### Step 2. Run everything

We are ready to start the node and sync the blockchain data:

- Start chain-maind, e.g.:

```bash
  $ ./chain-maind start
```

Sit back and wait for the syncing process. You can check the latest block height by

```bash
$ curl -s https://testnet-croeseid.crypto.org:26657/commit | jq "{height: .result.signed_header.header.height}"
```

