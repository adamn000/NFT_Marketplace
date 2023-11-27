// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {BasicNFT} from "../src/BasicNFT.sol";
import {HelperConfig} from "../script/NetworkConfig.s.sol";
import {DeployNFTMarketplace} from "../script/DeployNFTMarketplace.s.sol";
import {ERC721Mock} from "@openzeppelin/contracts/mocks/ERC721Mock.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TestNFTMarketplace is Test {
    NFTMarketplace marketplace;
    BasicNFT basicNFT;
    HelperConfig helperConfig;

    ERC721Mock nftToken = new ERC721Mock("NftToken", "NFTT");

    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");

    uint256 constant LIST_PRICE = 1 ether;
    uint256 constant NEW_PRICE = 2 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() public {
        DeployNFTMarketplace deployer = new DeployNFTMarketplace();
        (basicNFT, marketplace, helperConfig) = deployer.run();

        if (block.chainid == 31337) {
            ERC721Mock(nftToken).mint(USER1, 1);
            ERC721Mock(nftToken).mint(USER2, 2);
        }
        if (block.chainid == 11155111) {
            nftToken.mint(USER1, 1);
            nftToken.mint(USER2, 2);
        }
        vm.deal(USER1, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
    }

    ///// setup /////

    function testUserBalance() public {
        assertEq(USER1, nftToken.ownerOf(1));
        assertEq(USER2, nftToken.ownerOf(2));
    }

    ////// listToken //////

    function testUserCantListTokenIfNotApproved() public {
        vm.prank(USER1);
        vm.expectRevert(bytes("ERC721: caller is not token owner or approved"));
        marketplace.listToken(address(nftToken), 1, LIST_PRICE);
    }

    function testUserCanListTokenAndUpdateStructure() public {
        vm.startPrank(USER1);
        ERC721Mock(nftToken).approve(address(marketplace), 1);
        marketplace.listToken(address(nftToken), 1, LIST_PRICE);

        (IERC721 tokenAddres, uint256 tokenId, uint256 price, address seller, bool sold) =
            marketplace.getListedTokenInformation(0);

        assertEq(address(tokenAddres), address(nftToken));
        assertEq(tokenId, 1);
        assertEq(price, LIST_PRICE);
        assertEq(seller, USER1);
        assertEq(sold, false);
    }

    modifier listedToken() {
        vm.startPrank(USER1);
        ERC721Mock(nftToken).approve(address(marketplace), 1);
        marketplace.listToken(address(nftToken), 1, LIST_PRICE);
        _;
    }

    ////// buyToken //////

    function testRevertIfTokenIdDoesNotExist() public listedToken {
        vm.prank(USER1);
        vm.expectRevert(NFTMarketplace.TokenDoesNotExist.selector);
        marketplace.buyToken{value: LIST_PRICE}(10);
    }

    function testRevertIfTokenAlreadySold() public listedToken {
        vm.prank(USER2);
        marketplace.buyToken{value: LIST_PRICE}(0);

        vm.startPrank(USER1);
        vm.expectRevert(bytes("ERC721: caller is not token owner or approved"));
        marketplace.buyToken{value: LIST_PRICE}(0);
    }

    function testRevertIfWrongAmountEthSent() public listedToken {
        vm.prank(USER1);
        vm.expectRevert(NFTMarketplace.WrongEthAmountSent.selector);
        marketplace.buyToken{value: 0.5 ether}(0);
    }

    function testUserCanBuyToken() public listedToken {
        vm.prank(USER2);
        marketplace.buyToken{value: LIST_PRICE}(0);
        assertEq(nftToken.ownerOf(1), USER2);
    }
    ////// cancelListing /////

    function testOnlyOfferOwnerCanCancelListing() public listedToken {
        vm.prank(USER2);
        vm.expectRevert(NFTMarketplace.OnlyOwnerCanModifySellState.selector);
        marketplace.cancelListing(0);
    }

    function testOfferOwnerCanCancelListing() public listedToken {
        vm.prank(USER1);
        marketplace.cancelListing(0);

        (IERC721 tokenAddres, uint256 tokenId, uint256 price, address seller, bool sold) =
            marketplace.getListedTokenInformation(0);

        assertEq(address(tokenAddres), address(0));
        assertEq(tokenId, 0);
        assertEq(price, 0);
        assertEq(seller, address(0));
        assertEq(sold, false);
    }

    ////// editListingPrice /////

    function testOnlyOfferOwnerCanEditPrice() public listedToken {
        vm.prank(USER2);
        vm.expectRevert(NFTMarketplace.OnlyOwnerCanModifySellState.selector);
        marketplace.editListingPrice(0, NEW_PRICE);
    }

    function testOfferOwnerCanChangePrice() public listedToken {
        (,, uint256 price,,) = marketplace.getListedTokenInformation(0);

        vm.prank(USER1);
        marketplace.editListingPrice(0, NEW_PRICE);

        (,, uint256 updatedPrice,,) = marketplace.getListedTokenInformation(0);

        assertEq(price, LIST_PRICE);
        assertEq(updatedPrice, NEW_PRICE);
    }
}
