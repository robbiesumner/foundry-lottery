// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mock/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingNetworkConfig() internal returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (address vrfCoordinator, , , , , ) = helperConfig.activeConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64 subId) {
        console.log("Creating subscription on chain.id: ", block.chainid);
        vm.startBroadcast();
        subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Created subscription with id: ", subId);
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingNetworkConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingNetworkConfig() internal {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            address linkToken,

        ) = helperConfig.activeConfig();
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subscriptionId,
        address linkToken
    ) public {
        console.log("Funding subscription on chain.id: ", block.chainid);
        console.log("Funding subscription with id: ", subscriptionId);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingNetworkConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address raffle,
        address vrfCoordinator,
        uint64 subscriptionId,
        uint256 deployerKey
    ) public {
        console.log("Adding consumer on chain.id: ", block.chainid);
        console.log("Adding consumer to raffle: ", raffle);
        console.log("Adding consumer with subscriptionId: ", subscriptionId);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            raffle
        );
        vm.stopBroadcast();
    }

    function addConsumerUsingNetworkConfig(address raffle) internal {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.activeConfig();
        addConsumer(raffle, vrfCoordinator, subscriptionId, deployerKey);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingNetworkConfig(raffle);
    }
}
