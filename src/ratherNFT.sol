//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-06/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts-06/contracts/utils/Counters.sol";

contract ratherNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("RahterLabs", "RLABS") {}

    function mint(
        address user,
        string memory tokenData
    ) public returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _mint(user, newItemId);
        _setTokenURI(newItemId, tokenData);
        _tokenIds.increment();
        return newItemId;
    }

    function updateTokenURI(uint256 tokenId, string memory tokenData) public {
        // require(_exists(tokenId), "Token ID does not exist.");

        // require(ownerOf(tokenId) == msg.sender, "Not the token owner.");

        _setTokenURI(tokenId, tokenData);
    }

    function burn(uint256 tokenId) public {
        // Only the owner can burn the token
        // require(ownerOf(tokenId) == msg.sender, "Not the token owner.");
        _burn(tokenId);
        // Remove the tokenURI since the token is burned
        delete _tokenURIs[tokenId];
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenData
    ) internal override {
        _tokenURIs[tokenId] = tokenData;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist.");
        return _tokenURIs[tokenId];
    }
}
