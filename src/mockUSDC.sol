//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-06/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "mUSDC") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals()))); // Mint 1 million USDC for testing
    }

    function faucet(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}
