# ERC2771 Forwarder

This project implements a customized version of OpenZeppelin's ERC2771 forwarder contract with enhanced error handling capabilities. The forwarder enables meta-transactions by allowing users to submit transactions without paying gas fees directly, while also providing detailed error messages from the underlying contract execution.

Key features:
- Based on OpenZeppelin's ERC2771 implementation
- Returns detailed error messages from the underlying contract execution
- Supports meta-transactions for gasless transactions
- Maintains security and compatibility with the ERC2771 standard

## Deployments

| Network | Address |
|---------|---------|
| RAF Testnet | 0x0165878A594ca255338adfa4d48449f69242Eb8F |

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
