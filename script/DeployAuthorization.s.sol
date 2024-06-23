// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Authorization.sol";

contract DeployAuthorization is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        Authorization authorization = new Authorization();

        console.log(
            "Authorization contract deployed at:",
            address(authorization)
        );

        vm.stopBroadcast();
    }
}
