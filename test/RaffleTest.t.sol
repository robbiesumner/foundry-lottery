// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, Vm} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /** Events */
    event Raffle__Entered(address indexed entrant);

    Raffle raffle;
    uint256 private ENTRANCE_FEE;
    uint256 private INTERVAL;
    address private VRFCOORDINATOR;

    uint256 constant ENOUGH_BALANCE = 100 ether;
    address USER = makeAddr("user");

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle) = deployRaffle.run();

        // get deployment settings
        ENTRANCE_FEE = deployRaffle.ENTRANCE_FEE();
        INTERVAL = deployRaffle.INTERVAL();
        (VRFCOORDINATOR, , , , , ) = deployRaffle.helperConfig().activeConfig();

        vm.deal(USER, ENOUGH_BALANCE);
    }

    function testRaffleStartsOpen() external view {
        assert(raffle.getState() == Raffle.State.Open);
    }

    modifier raffleEntered() {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        _;
    }

    modifier timePassed() {
        vm.warp(block.timestamp + INTERVAL + 1);
        vm.roll(block.number + 1);
        _;
    }

    /************************************************************** */
    /********************* .enterRaffle() ***************************/
    /************************************************************** */

    function testRevertEnterWithoutEnoughETH() external {
        vm.prank(USER);
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE - 1}();
    }

    function testEntrantIsAddedToArray() external raffleEntered {
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

    function testRevertEnterWhenNotOpen() external raffleEntered timePassed {
        raffle.performUpkeep(""); // this will change the state to Calculating

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    /************************************************************** */
    /********************* .checkUpkeep() ***************************/
    /************************************************************** */

    function testCheckUpKeepReturnsFalseWhenItHasNoBalance()
        external
        timePassed
    {
        // act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen()
        external
        raffleEntered
        timePassed
    {
        // arrange
        raffle.performUpkeep("");

        // act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed()
        external
        raffleEntered
    {
        // act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood()
        external
        raffleEntered
        timePassed
    {
        // act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // assert
        assert(upkeepNeeded);
    }

    /************************************************************** */
    /********************* .performUpkeep() *************************/
    /************************************************************** */

    function testPerformUpkeepRunsWhenUpkeepNeeded()
        external
        raffleEntered
        timePassed
    {
        // act
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfUpkeepNotNeeded() external {
        // arrange
        uint256 contractBalance = address(raffle).balance;
        Raffle.State state = raffle.getState();

        // act
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                contractBalance,
                state
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepEmitsWinnerRequestedEventWithRequestId()
        external
        raffleEntered
        timePassed
    {
        // act
        vm.recordLogs(); // save all event logs
        raffle.performUpkeep(""); // => should emit WinnerRequested event

        // assert
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestId = logs[1].topics[1]; // 0 is the event signature, 1 is the requestId (first topic)

        assert(uint256(requestId) > 0);
    }

    function testPerformUpkeepChangesStateToCalculating()
        external
        raffleEntered
        timePassed
    {
        // act
        raffle.performUpkeep("");

        // assert
        assert(raffle.getState() == Raffle.State.Calculating);
    }

    /************************************************************** */
    /********************* .fulfillRandomWords() ********************/
    /************************************************************** */

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) external raffleEntered timePassed {
        // arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(VRFCOORDINATOR).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        external
        raffleEntered
        timePassed
    {
        // arrange
        uint256 additonalEntrants = 10;
        for (uint256 i = 1; i <= additonalEntrants; i++) {
            address newEntrant = address(uint160(i));
            hoax(newEntrant, ENOUGH_BALANCE);
            raffle.enterRaffle{value: ENTRANCE_FEE}();
        }
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestId = logs[1].topics[1];

        uint256 previousDrawTimestamp = raffle.getLastDrawTime();

        // act
        VRFCoordinatorV2Mock(VRFCOORDINATOR).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // assert
        assertTrue(raffle.getState() == Raffle.State.Open);
        assertTrue(raffle.getLastWinner() != address(0));
        assertEq(raffle.getNumberOfEntrants(), 0);
        assertGt(raffle.getLastDrawTime(), previousDrawTimestamp);
        assertEq(
            raffle.getLastWinner().balance,
            ENOUGH_BALANCE + ENTRANCE_FEE * additonalEntrants
        );
    }
}
