// see https://docs.soliditylang.org/en/v0.8.21/style-guide.html#order-of-layout for details on order of layout recommendations

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** Imports */

/** Interfaces */

/** Libraries */

/** Contracts */

/**
 * @title Raffle
 * @author Robbie Sumner
 * @notice This contract creates a raffle.
 * @dev Implements Chainlink VRFv2
 */
contract Raffle {
    /** Type Declarations */

    /** State Variables */
    uint256 private immutable i_fee;
    /// @dev duration raffle in seconds
    uint256 private immutable i_interval;
    address payable[] private s_entrants;
    uint256 private s_lastDrawTime;

    /** Events */
    event Raffle__Entered(address indexed entrant);

    /** Errors */
    error Raffle__NotEnoughETHSent();

    /** Modifiers */

    /** Functions */

    /// constructor
    constructor(uint256 entranceFee, uint256 interval) {
        i_fee = entranceFee;
        i_interval = interval;
        s_lastDrawTime = block.timestamp;
    }

    /// receive function

    /// fallback function

    // external functions
    function enterRaffle() external payable {
        if (msg.value < i_fee) {
            revert Raffle__NotEnoughETHSent();
        }
        s_entrants.push(payable(msg.sender));
        emit Raffle__Entered(msg.sender);
    }

    function getEntranceFee() external view returns (uint256) {
        return i_fee;
    }

    function getEntrant(uint256 index) external view returns (address) {
        return s_entrants[index];
    }

    // public functions
    function pickWinner() public {
        // TODO: handle function call: VRFv2
        if (block.timestamp - i_interval < s_lastDrawTime) {
            revert();
        }
    }

    // internal functions

    // private functions
}
