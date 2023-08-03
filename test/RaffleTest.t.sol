// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";

contract RaffleTest is Test {
    /** Events to check for */
    event Raffle__Entered(address indexed entrant);

    Raffle raffle;
    uint256 constant ENTRANCE_FEE = 1 ether;
    uint256 constant INTERVAL = 1 days;

    uint256 constant ENOUGH_BALANCE = 100 ether;
    address USER = makeAddr("user");

    function setUp() external {
        raffle = new Raffle(ENTRANCE_FEE, INTERVAL, address(0), 0x0, 0, 0);

        vm.deal(USER, ENOUGH_BALANCE);
    }

    function testRevertEnterWithoutEnoughETH() external {
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE - 1}();
    }

    function testEnterEmitsEnterEvent() external {
        vm.prank(USER);

        // expect raffle contract to emit Raffle__Entered(USER) event
        vm.expectEmit(address(raffle));
        emit Raffle__Entered(USER);

        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function testEntrantIsAddedToArray() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();

        // expect entrant to be added to array
        assertEq(raffle.getEntrant(0), USER);
    }
}
