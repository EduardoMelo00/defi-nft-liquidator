//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-06/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts-06/contracts/utils/Counters.sol";

contract ratherNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("RahterLabs", "RLABS") {}

    function mint(
        address user,
        string memory tokenURI
    ) public returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _mint(user, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenIds.increment();
        return newItemId;
    }
}
