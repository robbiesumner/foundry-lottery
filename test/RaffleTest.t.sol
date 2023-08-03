// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    /** Events */
    event Raffle__Entered(address indexed entrant);

    Raffle raffle;
    uint256 private ENTRANCE_FEE;
    uint256 private INTERVAL;

    uint256 constant ENOUGH_BALANCE = 100 ether;
    address USER = makeAddr("user");

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        raffle = deployRaffle.run();

        // get deployment settings
        ENTRANCE_FEE = deployRaffle.ENTRANCE_FEE();
        INTERVAL = deployRaffle.INTERVAL();

        vm.deal(USER, ENOUGH_BALANCE);
    }

    function testRaffleStartsOpen() external view {
        assert(raffle.getState() == Raffle.State.Open);
    }

    /************************************************************** */
    /********************* .enterRaffle() ***************************/
    /************************************************************** */

    function testRevertEnterWithoutEnoughETH() external {
        vm.prank(USER);
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE - 1}();
    }

    function testEntrantIsAddedToArray() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();

        // expect entrant to be added to array
        assertEq(raffle.getEntrant(0), USER);
    }

    function testEnterEmitsEnterEvent() external {
        vm.prank(USER);

        // expect raffle contract to emit Raffle__Entered(USER) event
        vm.expectEmit(true, false, false, false, address(raffle)); // this means there is a first topic(indexed), no second, no third and no data
        emit Raffle__Entered(USER);

        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    //! fails: no subsription
    // TODO: create subscription
    function testRevertEnterWhenNotOpen() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();

        vm.warp(block.timestamp + INTERVAL + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }
}
