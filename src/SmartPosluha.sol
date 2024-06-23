// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "forge-std/console.sol";

contract SmartPosluhaNFT is ERC721, Ownable {
    using Strings for uint256;

    uint256 private _tokenIds;

    struct ServiceType {
        string name;
        string description;
        string imageLink;
        uint256 duration;
        uint256 paymentAmount;
        address paymentToken;
        bool exists;
        uint256 gracePeriod;
    }

    struct ServiceDetails {
        uint256 typeId;
        uint256 mintDate;
        bool isPaid;
    }

    mapping(uint256 => ServiceType) public serviceTypes;
    mapping(uint256 => ServiceDetails) public serviceDetails;
    mapping(uint256 => bytes32) public consumptionHashes;

    uint256 public nextServiceTypeId;
    string public offerLink;
    string private _baseTokenURI;

    event ServiceTypeAdded(uint256 typeId);
    event ServiceTypeRemoved(uint256 typeId);
    event ServiceExtended(uint256 tokenId, uint256 newExpirationDate);
    event OfferLinkUpdated(string newOfferLink);
    event ServicePaid(uint256 tokenId, address payer);

    constructor(
        string memory initialOfferLink
    ) ERC721("SmartPosluha", "SPOSLUHA") Ownable(msg.sender) {
        offerLink = initialOfferLink;
    }

    function addServiceType(
        string memory name,
        string memory description,
        string memory imageLink,
        uint256 duration,
        uint256 paymentAmount,
        address paymentToken,
        uint256 gracePeriod
    ) public onlyOwner {
        serviceTypes[nextServiceTypeId] = ServiceType({
            name: name,
            description: description,
            imageLink: imageLink,
            duration: duration,
            paymentAmount: paymentAmount,
            paymentToken: paymentToken,
            exists: true,
            gracePeriod: gracePeriod
        });
        emit ServiceTypeAdded(nextServiceTypeId);
        nextServiceTypeId++;
    }

    function removeServiceType(uint256 typeId) public onlyOwner {
        require(serviceTypes[typeId].exists, "Service type does not exist");
        delete serviceTypes[typeId];
        emit ServiceTypeRemoved(typeId);
    }

    function updateOfferLink(string memory newOfferLink) public onlyOwner {
        offerLink = newOfferLink;
        emit OfferLinkUpdated(newOfferLink);
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function mintServiceNFT(
        address recipient,
        uint256 typeId
    ) public returns (uint256) {
        require(serviceTypes[typeId].exists, "Service type does not exist");

        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);

        serviceDetails[newItemId] = ServiceDetails({
            typeId: typeId,
            mintDate: block.timestamp,
            isPaid: false
        });

        return newItemId;
    }

    function payForService(uint256 tokenId) public {
        console.log("Starting payForService for tokenId:", tokenId);

        require(exists(tokenId), "Token does not exist");
        console.log("Token exists");

        require(
            ownerOf(tokenId) == msg.sender,
            "Only the owner can pay for the service"
        );
        console.log("Owner check passed");

        require(!serviceDetails[tokenId].isPaid, "Service already paid");
        console.log("Service not already paid");

        require(
            !isOfferExpired(tokenId) || isInGracePeriod(tokenId),
            "Offer has expired"
        );
        console.log("Offer not expired or in grace period");

        ServiceDetails storage details = serviceDetails[tokenId];
        ServiceType memory serviceType = serviceTypes[details.typeId];

        uint256 paymentAmount = getCurrentPaymentAmount(tokenId);
        console.log("Payment amount:", paymentAmount);

        IERC20 paymentToken = IERC20(serviceType.paymentToken);
        require(
            paymentToken.transferFrom(msg.sender, address(this), paymentAmount),
            "Payment failed"
        );
        console.log("Payment transfer successful");

        details.isPaid = true;
        emit ServicePaid(tokenId, msg.sender);
        console.log("Service marked as paid and event emitted");
    }

    function isOfferExpired(uint256 tokenId) public view returns (bool) {
        require(exists(tokenId), "Token does not exist");
        ServiceDetails memory details = serviceDetails[tokenId];
        ServiceType memory serviceType = serviceTypes[details.typeId];
        return block.timestamp > details.mintDate + serviceType.duration;
    }

    function isInGracePeriod(uint256 tokenId) public view returns (bool) {
        require(exists(tokenId), "Token does not exist");
        ServiceDetails memory details = serviceDetails[tokenId];
        ServiceType memory serviceType = serviceTypes[details.typeId];
        return
            block.timestamp > details.mintDate + serviceType.duration &&
            block.timestamp <=
            details.mintDate + serviceType.duration + serviceType.gracePeriod;
    }

    function getCurrentPaymentAmount(
        uint256 tokenId
    ) public view returns (uint256) {
        require(exists(tokenId), "Token does not exist");
        ServiceDetails memory details = serviceDetails[tokenId];
        ServiceType memory serviceType = serviceTypes[details.typeId];

        return serviceType.paymentAmount;
    }

    function setConsumptionHash(
        uint256 tokenId,
        bytes32 consumptionHash
    ) public onlyOwner {
        require(exists(tokenId), "Token does not exist");
        consumptionHashes[tokenId] = consumptionHash;
    }

    function withdrawPayments(address tokenAddress) public onlyOwner {
        IERC20 paymentToken = IERC20(tokenAddress);
        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");
        paymentToken.transfer(owner(), balance);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(exists(tokenId), "Token does not exist");

        ServiceDetails memory details = serviceDetails[tokenId];
        ServiceType memory serviceType = serviceTypes[details.typeId];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        serviceType.name,
                        '", "description": "',
                        serviceType.description,
                        '", "image": "',
                        serviceType.imageLink,
                        '", "attributes": [{"trait_type": "Offer Link", "value": "',
                        offerLink,
                        '"}, {"trait_type": "Expiration Date", "value": "',
                        (details.mintDate + serviceType.duration).toString(),
                        '"}, {"trait_type": "Is Paid", "value": "',
                        details.isPaid ? "true" : "false",
                        '"}, {"trait_type": "Payment Amount", "value": "',
                        getCurrentPaymentAmount(tokenId).toString(),
                        '"}]}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getServiceDetails(
        uint256 tokenId
    )
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            address,
            bool
        )
    {
        require(exists(tokenId), "Token does not exist");
        ServiceDetails memory details = serviceDetails[tokenId];
        ServiceType memory serviceType = serviceTypes[details.typeId];
        return (
            serviceType.name,
            serviceType.description,
            serviceType.imageLink,
            serviceType.duration,
            serviceType.paymentAmount,
            serviceType.paymentToken,
            details.isPaid
        );
    }

    function getServiceTypeDetails(
        uint256 typeId
    )
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            address
        )
    {
        require(serviceTypes[typeId].exists, "Service type does not exist");
        ServiceType memory serviceType = serviceTypes[typeId];
        return (
            serviceType.name,
            serviceType.description,
            serviceType.imageLink,
            serviceType.duration,
            serviceType.paymentAmount,
            serviceType.paymentToken
        );
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _tokenIds >= tokenId;
    }
}
