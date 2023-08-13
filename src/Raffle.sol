// see https://docs.soliditylang.org/en/v0.8.21/style-guide.html#order-of-layout for details on order of layout recommendations

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** Imports */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/** Interfaces */

/** Libraries */

/** Contracts */

/**
 * @title Raffle
 * @author Robbie Sumner
 * @notice This contract creates a raffle.
 * @dev Implements Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /** Type Declarations */
    enum State {
        Open,
        Calculating
    }

    /** State Variables */
    uint256 private immutable i_fee;
    /// @dev duration raffle in seconds
    uint256 private immutable i_interval;
    address payable[] private s_entrants;
    uint256 private s_lastDrawTime;
    address payable private s_lastWinner;
    State private s_state;

    /// @dev Chainlink VRFv2
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    /** Events */
    event Raffle__Entered(address indexed entrant);
    event Raffle__WinnerRequested(uint256 indexed requestId);
    event Raffle__WinnerPicked(address indexed winner);

    /** Errors */
    error Raffle__NotEnoughETHSent();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    error Raffle__UpKeepNotNeeded(uint256 contractBalance, State state);

    /** Modifiers */

    /** Functions */

    /// constructor
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinatorAddress,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorAddress) {
        i_fee = entranceFee;
        i_interval = interval;
        s_lastDrawTime = block.timestamp;
        s_state = State.Open;

        /// @dev Chainlink VRFv2
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    /// receive function

    /// fallback function

    // external functions
    function enterRaffle() external payable {
        if (msg.value < i_fee) {
            revert Raffle__NotEnoughETHSent();
        }
        if (s_state != State.Open) {
            revert Raffle__NotOpen();
        }
        s_entrants.push(payable(msg.sender));
        emit Raffle__Entered(msg.sender);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_state);
        }
        pickWinner();
    }

    // external view functions
    /**
     * @dev This is the function Chainlink Automation calls to check if it should call performUpkeep
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = block.timestamp - s_lastDrawTime >= i_interval;
        bool isOpen = s_state == State.Open;
        bool hasBalance = address(this).balance > 0;

        return (timeHasPassed && isOpen && hasBalance, "");
    }

    function getEntranceFee() external view returns (uint256) {
        return i_fee;
    }

    function getEntrant(uint256 index) external view returns (address) {
        return s_entrants[index];
    }

    function getState() external view returns (State) {
        return s_state;
    }

    // public functions
    function pickWinner() internal {
        s_state = State.Calculating;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit Raffle__WinnerRequested(requestId);
    }

    // internal functions
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        // Checks

        // Effects
        uint256 winnerIndex = randomWords[0] % s_entrants.length;
        s_lastWinner = s_entrants[winnerIndex];
        s_entrants = new address payable[](0);
        s_lastDrawTime = block.timestamp;
        s_state = State.Open;
        emit Raffle__WinnerPicked(s_lastWinner);

        // Interactions
        (bool s, ) = s_lastWinner.call{value: address(this).balance}("");
        if (!s) {
            revert Raffle__TransferFailed();
        }
    }

    // private functions
}
