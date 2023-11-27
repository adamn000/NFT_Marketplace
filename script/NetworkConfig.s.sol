// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {ERC721Mock} from "@openzeppelin/contracts/mocks/ERC721Mock.sol";
import {BasicNFT} from "../src/BasicNFT.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;
    BasicNFT public basicNFT;

    struct NetworkConfig {
        address nftTokenAddress;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public returns (NetworkConfig memory sepoliaNetworkConfig) {
        vm.startBroadcast();
        basicNFT = new BasicNFT();
        vm.stopBroadcast();
        sepoliaNetworkConfig =
            NetworkConfig({nftTokenAddress: address(basicNFT), deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilEthConfig) {
        vm.startBroadcast();
        ERC721Mock nftTokenAnvil = new ERC721Mock("NFTToken", "NFTT");
        vm.stopBroadcast();

        anvilEthConfig =
            NetworkConfig({nftTokenAddress: address(nftTokenAnvil), deployerKey: DEFAULT_ANVIL_PRIVATE_KEY});
    }
}
