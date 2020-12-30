If you have a node started earlier with the version v.0.7.\* (testnet-croeseid-1), kindly follow this instructionsand upgrade to v.0.8 (testnet-croeseid-2) with the new configuration script.


# Obtain and run the new reconfig.sh

```bash
$ curl -sSL https://raw.githubusercontent.com/crypto-com/testnets/main/testnet-croeseid-2/1-click-reconfig/reconfig.sh | sudo tee /chain/reconfig.sh >/dev/null
$ sudo -u crypto /chain/reconfig.sh
```

## Choose `1` for the `testnet-croeseid-2` network
```bash
You can select the following networks to join
        0. testnet-croeseid-1
        1. testnet-croeseid-2
```
