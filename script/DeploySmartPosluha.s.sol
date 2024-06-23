// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/SmartPosluha.sol";

contract DeploySmartPosluhaNFT is Script {
    function run() external {
        string memory initialOfferLink = "https://fex.net/s/4dsbt8a";

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address auth = 0xAF966e9F18aEF846Bd5AF2ce2627Fa4d92e244dd;

        vm.startBroadcast(deployerPrivateKey);
        SmartPosluhaNFT nftContract = new SmartPosluhaNFT(
            initialOfferLink,
            auth
        );
        vm.stopBroadcast();
    }
}
