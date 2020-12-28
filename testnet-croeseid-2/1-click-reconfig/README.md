# Upgrade from existing 1-click image

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