// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Authorization is Ownable {
    mapping(address => bool) private authorized;

    event AuthorizationChanged(address indexed account, bool isAuthorized);

    constructor() Ownable(msg.sender) {}

    // Function to authorize an account
    function authorizeAccount(
        address account,
        bool isAuthorized
    ) external onlyOwner {
        authorized[account] = isAuthorized;
        emit AuthorizationChanged(account, isAuthorized);
    }

    // Function to check if an account is authorized
    function isAuthorized(address account) external view returns (bool) {
        return authorized[account];
    }
}
