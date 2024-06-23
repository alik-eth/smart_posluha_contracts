// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "ds-test/test.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/SmartPosluha.sol";
import "forge-std/console.sol";

contract MockERC20 is IERC20 {
    string public name = "Mock ERC20";
    string public symbol = "MERC20";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _totalSupply, address initialOwner) {
        totalSupply = _totalSupply;
        balanceOf[initialOwner] = _totalSupply;
        console.log(
            "MockERC20 Constructor: Initial owner balance set to",
            balanceOf[initialOwner]
        );
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        console.log("Transfer: from", msg.sender);
        console.log("to: ", to);
        console.log("amount", amount);
        console.log("New balance of sender:", balanceOf[msg.sender]);
        console.log("New balance of receiver:", balanceOf[to]);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract SmartPosluhaNFTTest is Test {
    SmartPosluhaNFT public nft;
    MockERC20 public erc20;

    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);

    function setUp() public {
        erc20 = new MockERC20(1e24, owner);
        nft = new SmartPosluhaNFT("https://example.com");
        nft.transferOwnership(owner);

        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);

        // Transfer enough ERC20 tokens to user1
        vm.prank(owner);
        bool success1 = erc20.transfer(user1, 100 ether);
        console.log("Transfer to user1 success: ", success1);
        console.log(
            "User1 ERC20 balance after transfer: ",
            erc20.balanceOf(user1)
        );

        vm.prank(user2);
        erc20.approve(address(nft), 100 ether);

        // Transfer enough ERC20 tokens to user2
        vm.prank(owner);
        bool success2 = erc20.transfer(user2, 100 ether);
        console.log("Transfer to user2 success: ", success2);
        console.log(
            "User2 ERC20 balance after transfer: ",
            erc20.balanceOf(user2)
        );
    }

    function testAddServiceType() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        (
            string memory name,
            string memory description,
            string memory imageLink,
            uint256 duration,
            uint256 paymentAmount,
            address paymentToken
        ) = nft.getServiceTypeDetails(0);

        assertEq(name, "Service 1");
        assertEq(description, "Description 1");
        assertEq(imageLink, "https://image-link.com/1");
        assertEq(duration, 30 days);
        assertEq(paymentAmount, 100 ether);
        assertEq(paymentToken, address(erc20));
    }

    function testRemoveServiceType() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        vm.prank(owner);
        nft.removeServiceType(0);
        vm.expectRevert("Service type does not exist");
        nft.getServiceTypeDetails(0);
    }

    function testMintServiceNFT() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);
        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(tokenId), user1);

        (uint256 typeId, uint256 mintDate, bool isPaid) = nft.serviceDetails(
            tokenId
        );
        assertEq(typeId, 0);
        assertEq(isPaid, false);
    }

    function testFailMintServiceNFTNonExistentType() public {
        vm.prank(user1);
        nft.mintServiceNFT(user1, 0);
    }

    function testPayForServiceNotOwner() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);

        vm.prank(user2);
        nft.payForService(tokenId);
    }

    function testFailPayForServiceAlreadyPaid() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);

        vm.prank(user1);
        erc20.approve(address(nft), 100 ether);

        vm.prank(user1);
        nft.payForService(tokenId);

        vm.prank(user1);
        nft.payForService(tokenId);
    }

    function testFailPayForServiceExpired() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        // Ensure user1 has enough ERC20 tokens
        vm.prank(owner);
        erc20.transfer(user1, 100 ether);
        console.log(
            "User1 ERC20 balance after transfer: ",
            erc20.balanceOf(user1)
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);

        vm.warp(block.timestamp + 31 days); // Move forward in time to after the service duration

        vm.prank(user1);
        erc20.approve(address(nft), 100 ether);

        // Log approval amount
        console.log("Approved amount: ", erc20.allowance(user1, address(nft)));

        // Check isOfferExpired and isInGracePeriod
        bool expired = nft.isOfferExpired(tokenId);
        bool inGracePeriod = nft.isInGracePeriod(tokenId);
        console.log("Offer expired:", expired);
        console.log("In grace period:", inGracePeriod);

        vm.expectRevert("Offer has expired");
        vm.prank(user1);
        nft.payForService(tokenId);
    }

    function testSetConsumptionHash() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);

        bytes32 consumptionHash = keccak256(abi.encodePacked("some data"));
        vm.prank(owner);
        nft.setConsumptionHash(tokenId, consumptionHash);

        bytes32 storedHash = nft.consumptionHashes(tokenId);
        assertEq(storedHash, consumptionHash);
    }

    function testFailSetConsumptionHashNotOwner() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);

        bytes32 consumptionHash = keccak256(abi.encodePacked("some data"));
        vm.prank(user1);
        nft.setConsumptionHash(tokenId, consumptionHash);
    }

    function testFailWithdrawPaymentsNotOwner() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);

        vm.prank(user1);
        erc20.approve(address(nft), 100 ether);

        vm.prank(user1);
        nft.payForService(tokenId);

        vm.prank(user1);
        nft.withdrawPayments(address(erc20));
    }

    function testUpdateOfferLink() public {
        vm.prank(owner);
        string memory newOfferLink = "https://new-example.com";
        nft.updateOfferLink(newOfferLink);

        assertEq(nft.offerLink(), newOfferLink);
    }

    function testPayForService() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        console.log("Owner initial ERC20 balance: ", erc20.balanceOf(owner));
        // Transfer enough ERC20 tokens to user1
        vm.prank(owner);
        erc20.transfer(user1, 100 ether);

        // Log user1's balance
        console.log(
            "User1 ERC20 balance before minting: ",
            erc20.balanceOf(user1)
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);

        // Log tokenId
        console.log("Minted tokenId: ", tokenId);

        vm.prank(user1);
        erc20.approve(address(nft), 100 ether);

        // Log approval amount
        console.log("Approved amount: ", erc20.allowance(user1, address(nft)));

        vm.prank(user1);
        nft.payForService(tokenId);

        (, , bool isPaid) = nft.serviceDetails(tokenId);

        // Log isPaid
        console.log("isPaid: ", isPaid);

        assertEq(isPaid, true);
    }

    function testPayForServiceInGracePeriod() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        // Transfer enough ERC20 tokens to user1
        vm.prank(owner);
        erc20.transfer(user1, 100 ether);
        console.log(
            "User1 ERC20 balance after transfer: ",
            erc20.balanceOf(user1)
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);

        vm.warp(block.timestamp + 30 days + 1 days); // Move forward in time to within the grace period

        vm.prank(user1);
        erc20.approve(address(nft), 100 ether);

        // Log approval amount
        console.log("Approved amount: ", erc20.allowance(user1, address(nft)));

        console.log("here1");
        vm.prank(user1);
        nft.payForService(tokenId);

        (, , bool isPaid) = nft.serviceDetails(tokenId);

        // Log isPaid
        console.log("isPaid: ", isPaid);

        assertEq(isPaid, true);
    }

    function testWithdrawPayments() public {
        vm.prank(owner);
        nft.addServiceType(
            "Service 1",
            "Description 1",
            "https://image-link.com/1",
            30 days,
            100 ether,
            address(erc20),
            7 days
        );

        vm.prank(user1);
        uint256 tokenId = nft.mintServiceNFT(user1, 0);

        vm.prank(user1);
        erc20.approve(address(nft), 100 ether);

        vm.prank(user1);
        nft.payForService(tokenId);

        uint256 initialBalance = erc20.balanceOf(owner);

        // Log initial balance
        console.log("Owner initial balance: ", initialBalance);

        vm.prank(owner);
        nft.withdrawPayments(address(erc20));

        uint256 finalBalance = erc20.balanceOf(owner);

        // Log final balance
        console.log("Owner final balance: ", finalBalance);

        assertEq(finalBalance, initialBalance + 100 ether);
    }
}
