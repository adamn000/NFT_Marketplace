// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace {
    error OnlyOwnerCanModifySellState();
    error WrongEthAmountSent();
    error TokenDoesNotExist();

    constructor() {}

    struct ListedToken {
        IERC721 tokenAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool sold;
    }

    uint256 listedTokenCounter;

    mapping(uint256 => ListedToken) listedTokenId;

    modifier onlyTokenSeller(uint256 index) {
        ListedToken memory listedToken = listedTokenId[index];
        if (listedToken.seller != msg.sender) {
            revert OnlyOwnerCanModifySellState();
        }
        _;
    }

    //zabezpieczenia
    function listToken(address tokenAddress, uint256 tokenId, uint256 price) external {
        ListedToken storage listedToken = listedTokenId[listedTokenCounter];
        listedToken.tokenAddress = IERC721(tokenAddress);
        listedToken.tokenId = tokenId;
        listedToken.price = price;
        listedToken.seller = msg.sender;
        listedToken.sold = false;

        IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);
        listedTokenCounter++;
    }

    function buyToken(uint256 index) external payable {
        ListedToken memory listedToken = listedTokenId[index];
        if (listedToken.seller == address(0)) revert TokenDoesNotExist();
        if (msg.value != listedToken.price) revert WrongEthAmountSent();

        IERC721(listedToken.tokenAddress).transferFrom(address(this), msg.sender, listedToken.tokenId);

        listedToken.sold = true;
    }

    function cancelListing(uint256 index) external onlyTokenSeller(index) {
        delete listedTokenId[index];
    }

    function editListingPrice(uint256 index, uint256 newPrice) external onlyTokenSeller(index) {
        ListedToken storage listedToken = listedTokenId[index];
        listedToken.price = newPrice;
    }

    function getListedTokenStruct(uint256 _index) public view returns (ListedToken memory) {
        return listedTokenId[_index];
    }

    function getListedTokenInformation(uint256 _index) public view returns (IERC721, uint256, uint256, address, bool) {
        ListedToken memory listedToken = listedTokenId[_index];

        return (listedToken.tokenAddress, listedToken.tokenId, listedToken.price, listedToken.seller, listedToken.sold);
    }
}
