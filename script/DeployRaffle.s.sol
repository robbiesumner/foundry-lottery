// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    uint256 public constant ENTRANCE_FEE = 0.1 ether;
    uint256 public constant INTERVAL = 30 seconds;

    function run() external returns (Raffle) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinator,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit
        ) = helperConfig.activeConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            ENTRANCE_FEE,
            INTERVAL,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        return raffle;
    }
}
