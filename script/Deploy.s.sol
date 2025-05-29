// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { ERC2771Forwarder } from "../src/ERC2771Forwarder.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY_1");
        vm.startBroadcast(deployerPrivateKey);

        ERC2771Forwarder forwarder = new ERC2771Forwarder("RAF");
        console2.log("ERC2771Forwarder deployed at:", address(forwarder));

        vm.stopBroadcast();
    }
}
