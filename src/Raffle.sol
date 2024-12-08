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
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState); // conditions for picking a winner are not met

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
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");  // not gas efficient because it stores string
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());  // only works on certain version

        // check if mesage value is greater than the entrance fee requirement
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        // check if rafflestate is open
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender)); // add the message sender into s_players array

        emit RaffleEntered(msg.sender); // emit event, makes migration easier and make front-end indexing easier
    }

    // When should the winner be picked?
    /**
     * @dev This is the fucntion that the chainlink nodes will call to see if the lottery is ready to have a winner picked.
     *  The following should be true in order for upKeepNeeded to be true:
     *  1. The time interval has passed between raffle run
     *  2. The lottery is open
     *  3. The contract has ETH
     *  4. Implicitly, your subscription has LINK
     *  @param -ignored
     *  @return upkeepNeeded - true if it's time to restart the lottery
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        // 1. The time interval has passed between raffle run
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);

        // 2. The lottery is open
        bool isOpen = s_raffleState == RaffleState.OPEN;

        // 3. The contract has ETH
        bool hasBalance = address(this).balance > 0;

        // 3.5. The contract has players
        bool hasPlayers = s_players.length > 0;

        // if everything is true, upkeepNeeded is also true
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;

        return (upkeepNeeded, "");
    }

    // 1. get a random number
    // 2. use random number to pick a player
    // 3. be automatically called
    function performUpkeep(bytes calldata /* performData */ ) external {
        // check to see if enough time has passed
        (bool upkeepNeeded,) = checkUpkeep(""); // call checkUpkeep function to see if upkeep is needed

        // if upkeep is not needed, revert error
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING; // Set raffleState as calculating

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

        // Quiz...is this redundant?
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        // Checks (Make sure we want to run this function)

        // Effect (internal contract state)
        uint256 indexOfWinner = randomWords[0] % s_players.length; // get the index from randomWords
        address payable recentWinner = s_players[indexOfWinner]; // declare winner from the index
        s_recentWinner = recentWinner; // set s_recentWinner
        s_raffleState = RaffleState.OPEN; // reopen the raffle
        s_players = new address payable[](0); // reset the players array
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);

        // interactions (external contract interaction)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }
}
