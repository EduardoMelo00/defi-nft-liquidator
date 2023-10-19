// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {UserPosition} from "../src/getUserPosition.sol";

contract UserPositionDeploymentScript is Script {
    address public deployedUserPosition;

    function setUp() public {
        // Initial setup if needed
    }

    function run() public {
        // Extract the arguments

        bytes32 privateKeyBytes32 = vm.envBytes32("PRIVATE_KEY");
        uint256 privateKeyInt = uint256(privateKeyBytes32);

        vm.startBroadcast(privateKeyInt);

        UserPosition token = new UserPosition(
            0x3cBe63aAcF6A064D32072a630A3eab7545C54d78,
            0x5B39D7651F12FF19558a5B0C45AAD20156Ab760b,
            0x07865c6E87B9F70255377e024ace6630C1Eaa37F
        );

        vm.stopBroadcast();
    }
}
