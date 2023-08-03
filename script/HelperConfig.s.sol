// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    error HelperConfig__UnsupportedNetwork();

    NetworkConfig public activeConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeConfig = getSepoliaETHConfig();
        } else if (block.chainid == 31337) {
            activeConfig = createAndGetAnvilConfig();
        } else {
            revert HelperConfig__UnsupportedNetwork();
        }
    }

    function getSepoliaETHConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, // TODO: get my own subscription
                callbackGasLimit: 500000
            });
    }

    function createAndGetAnvilConfig() public returns (NetworkConfig memory) {
        // mocks already deployed
        if (activeConfig.vrfCoordinator != address(0)) {
            return activeConfig;
        }

        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        vm.stopBroadcast();

        return
            NetworkConfig({
                vrfCoordinator: address(vrfCoordinator),
                keyHash: bytes32(keccak256("mock")),
                subscriptionId: 0, // TODO: get this with script
                callbackGasLimit: 500000
            });
    }
}
