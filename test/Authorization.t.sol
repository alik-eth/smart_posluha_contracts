// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Authorization.sol";

contract AuthorizationTest is Test {
    Authorization private authorization;
    address private owner = address(0x123);
    address private authorizedAccount = address(0x456);
    address private unauthorizedAccount = address(0x789);
    address private anotherAccount = address(0xabc);

    function setUp() public {
        vm.prank(owner);
        authorization = new Authorization();
    }

    function testAuthorizeAccountAsOwner() public {
        vm.prank(owner);
        authorization.authorizeAccount(authorizedAccount, true);

        bool isAuthorized = authorization.isAuthorized(authorizedAccount);
        assertTrue(isAuthorized, "The account should be authorized");
    }

    function testFailAuthorizeAccountAsNonOwner() public {
        vm.prank(anotherAccount);
        authorization.authorizeAccount(unauthorizedAccount, true);
    }

    function testDeauthorizeAccountAsOwner() public {
        vm.prank(owner);
        authorization.authorizeAccount(authorizedAccount, true);

        bool isAuthorized = authorization.isAuthorized(authorizedAccount);
        assertTrue(isAuthorized, "The account should be authorized");

        vm.prank(owner);
        authorization.authorizeAccount(authorizedAccount, false);

        isAuthorized = authorization.isAuthorized(authorizedAccount);
        assertFalse(isAuthorized, "The account should be deauthorized");
    }

    function testIsAuthorizedForUnauthorizedAccount() public {
        bool isAuthorized = authorization.isAuthorized(unauthorizedAccount);
        assertFalse(isAuthorized, "The account should not be authorized");
    }
}
