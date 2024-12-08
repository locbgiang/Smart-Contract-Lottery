// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol"; // import from foundry's forge-std library, it provides utilities for scripting deployments or setup
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol"; // A mock implementation of Chainlink VRF coordinator, used for testing
import {LinkToken} from "../test/mocks/LinkToken.sol";

// import LinkToken; A mock link token contract used in testing environments

// Contains constants that are shared across configurations.
abstract contract CodeConstants {
    /* VRF Mock Values */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;

    // LINK / ETH Price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

/**
 * @title HelperConfig
 * @author Loc Giang
 * @notice This Solidity script provides a helper configuration for deploying and testing contracts on different blockchain networks, such as:
 * Ethereum Sepolia and local Anvil test networks. It includes tools for managing VRF (Verifiable Random Function) mock setups and configurations
 * for deployment environments.
 */
contract HelperConfig is Script, CodeConstants {
    /**
     * Errors
     */
    error HelperConfig__InvalidChainId(); // Thrown when an unsupported chain ID is provided.

    // struct is a custom data type that allows you to group multiple variables together under one structure.
    struct NetworkConfig {
        uint256 entranceFee; // minimum fee to participate in a raffle
        uint256 interval; // time interval between actions like picking a winner
        address vrfCoordinator; // address of the VRF coordinator
        bytes32 gasLane; // gas lane key for vrf request
        uint32 callbackGasLimit; // maximum gas used in the vrf callback
        uint256 subscriptionId; // vrf subscription id
        address link; // address of the link token
        address account; // default account for transactions
    }
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs; // maps chain IDs to their respective configurations

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    /**
     * Functions
     */

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000,
                subscriptionId: 113128606011855012763239084462199827892700791750814251836608413918377366988816,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0x352391E0B031D7a6E82C85fb8096fb3FCC347253
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // check to see if we set an active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // Deploy mocks and such
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorMock), // running the mock vrf coordinator up there =)
            // doesnt matter
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000, // 500k gas
            subscriptionId: 0, // might have to fix this
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });
        return localNetworkConfig;
    }
}
