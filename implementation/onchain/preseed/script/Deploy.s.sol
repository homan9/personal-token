// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {PreSeed} from "../src/PreSeed.sol";
import {InitialInvestment} from "../src/IPreSeed.sol";

contract DeployPreSeed is Script {
    function run() external {
        address village = 0xA2C7d149fD50A277313F2349A558fdD59FCC6bCA;

        InitialInvestment[] memory initialInvestments = new InitialInvestment[](1);
        initialInvestments[0] = InitialInvestment({
            villagerId: 1,
            amount: 25_000e6 // 25,000 USDC
        });

        vm.startBroadcast();
        new PreSeed(village, initialInvestments);
        vm.stopBroadcast();
    }
}
