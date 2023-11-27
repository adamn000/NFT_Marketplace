// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./NetworkConfig.s.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {BasicNFT} from "../src/BasicNFT.sol";

contract DeployNFTMarketplace is Script {
    function run() external returns (BasicNFT, NFTMarketplace, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address nftTokenAddress, uint256 deployerKey) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        BasicNFT basicNFT = new BasicNFT();
        NFTMarketplace marketplace = new NFTMarketplace();
        vm.stopBroadcast();
        return (basicNFT, marketplace, helperConfig);
    }
}
