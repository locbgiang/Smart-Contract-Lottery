// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

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

}
