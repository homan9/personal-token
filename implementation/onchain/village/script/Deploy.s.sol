// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Village} from "../src/Village.sol";

contract DeployVillage is Script {
    function run() public {
        vm.startBroadcast();

        Village village = new Village();

        vm.stopBroadcast();

        console.log("Village deployed at:", address(village));
        console.log("Owner:", village.owner());
    }
}
