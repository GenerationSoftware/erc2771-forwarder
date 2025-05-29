#! /bin/bash

forge test && forge clean && forge build

forge script -vvv script/Deploy.s.sol \
    --rpc-url $ETH_RPC_URL \
    --broadcast \
    --private-key $ANVIL_PRIVATE_KEY_1
