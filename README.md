## Challenge settings

**To perform test locally we need to change the priceFeed Address** 

  ## Test Locally (mainnet fork)   

```shell
$ getLatestPrice(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419)
```

  ## Test on goerli 
  ```shell
$ getLatestPrice(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e)
```

   ## Setup goerli deply

-   **comptrollerCompound**: 0x3cBe63aAcF6A064D32072a630A3eab7545C54d78
-   **nftAddress**: 0xfCBDCD29f15dC521Dfe9edA53f5B891753A2A560
-   **usdcTokenAddress**: 0x07865c6E87B9F70255377e024ace6630C1Eaa37F


## Basic informations

-   **The lending protocol used was Compound**
-   **Chainlink keeper to let NFT dynamic to test is here : https://automation.chain.link/goerli/18059277995448472538181535923858264013133996628068180111911675908649971119485**




## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
