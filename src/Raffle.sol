// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol"; // for VRF random number functionality.
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol"; // for constructing requests to Chainlink VRF
import {console} from "forge-std/console.sol"; //  forge library for console.sol to allow debugging during development

/**
 * @title A Raffle contract
 * @author Loc Giang
 * @notice This contract is for creating a sample raffle
 * @dev Implement Chainlink VRF2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    // custom error definition for optimized gas usage
    error Raffle__SendMoreToEnterRaffle(); // not enough eth to enter raffle
    error Raffle__RaffleNotOpen(); // raffle is not accepting entries
    error Raffle__TransferFailed(); // eth transfer to winner failed
    error Raffle__UpkeepNotNeeded(); // conditions for picking a winner are not met

    /**
     * Type Declarations
     */
    // defines the raffle's state
    enum RaffleState {
        OPEN, // the raffle is accepting entries
        CALCULATING // a winner is being determined
    }

    /**
     * State Variables
     */
    // constants
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // needed confirmation
    uint32 private constant NUM_WORDS = 1; // minimum words

    // immutable variables set during contract deployment
    uint256 private immutable i_entranceFee; // entry cost for the raffle
    // @dev the duration of the lottery in seconds
    uint256 private immutable i_interval; // minimum time between raffles

    // VRF configuration parameters
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    // storage variables
    address payable[] private s_players; // array of participants (addresses)
    uint256 private s_lastTimeStamp; // timestamp of the last raffle
    address private s_recentWinner; // last raffle's winner
    RaffleState private s_raffleState; // current state of the raffle

    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /**
     * Constructor
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    /**
     * Functions
     */
}
