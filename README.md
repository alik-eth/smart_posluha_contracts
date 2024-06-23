# SmartPosluhaNFT - README.md

## Overview

SmartPosluhaNFT is a Solidity-based smart contract for creating and managing ERC721 non-fungible tokens (NFTs) representing various service types. Each NFT can be associated with a specific service, including its details and payment status.

## Features

- **Minting NFTs**: Mint new NFTs representing different services.
- **Service Types**: Add, remove, and manage different types of services.
- **Payment System**: Pay for services using ERC20 tokens.
- **Offer Link**: Update the offer link associated with the services.
- **Service Management**: Extend services, check expiration and grace periods, and more.
- **Consumption Hash**: Set consumption hashes for tracking service consumption.

## Contract Details

### State Variables

- `serviceTypes`: Mapping of service type IDs to `ServiceType` structs.
- `serviceDetails`: Mapping of token IDs to `ServiceDetails` structs.
- `consumptionHashes`: Mapping of token IDs to consumption hashes.
- `nextServiceTypeId`: ID for the next service type.
- `offerLink`: Link associated with the services.
- `_baseTokenURI`: Base URI for token metadata.

### Structs

#### ServiceType

- `name`: Name of the service.
- `description`: Description of the service.
- `imageLink`: Link to an image representing the service.
- `duration`: Duration of the service.
- `paymentAmount`: Payment amount for the service.
- `paymentToken`: ERC20 token address for payment.
- `exists`: Boolean indicating if the service type exists.
- `gracePeriod`: Grace period after the service duration.

#### ServiceDetails

- `typeId`: ID of the service type.
- `mintDate`: Mint date of the NFT.
- `isPaid`: Boolean indicating if the service has been paid for.

### Events

- `ServiceTypeAdded(uint256 typeId)`: Emitted when a new service type is added.
- `ServiceTypeRemoved(uint256 typeId)`: Emitted when a service type is removed.
- `ServiceExtended(uint256 tokenId, uint256 newExpirationDate)`: Emitted when a service is extended.
- `OfferLinkUpdated(string newOfferLink)`: Emitted when the offer link is updated.
- `ServicePaid(uint256 tokenId, address payer)`: Emitted when a service is paid for.

### Functions

#### Constructor

- `constructor(string memory initialOfferLink)`: Initializes the contract with an initial offer link.

#### Owner Functions

- `addServiceType(string memory name, string memory description, string memory imageLink, uint256 duration, uint256 paymentAmount, address paymentToken, uint256 gracePeriod)`: Adds a new service type.
- `removeServiceType(uint256 typeId)`: Removes a service type.
- `updateOfferLink(string memory newOfferLink)`: Updates the offer link.
- `setBaseTokenURI(string memory baseTokenURI)`: Sets the base token URI.
- `withdrawPayments(address tokenAddress)`: Withdraws payments received in ERC20 tokens.
- `setConsumptionHash(uint256 tokenId, bytes32 consumptionHash)`: Sets the consumption hash for a token.

#### Public Functions

- `mintServiceNFT(address recipient, uint256 typeId)`: Mints a new NFT for a specific service type.
- `payForService(uint256 tokenId)`: Pays for the service associated with a token.
- `isOfferExpired(uint256 tokenId)`: Checks if the offer for a token is expired.
- `isInGracePeriod(uint256 tokenId)`: Checks if a token is within its grace period.
- `getCurrentPaymentAmount(uint256 tokenId)`: Returns the current payment amount for a token.
- `tokenURI(uint256 tokenId)`: Returns the token URI for a specific token.
- `getServiceDetails(uint256 tokenId)`: Returns the details of a service associated with a token.
- `getServiceTypeDetails(uint256 typeId)`: Returns the details of a service type.

### Internal Functions

- `_baseURI()`: Returns the base URI for token metadata.
- `exists(uint256 tokenId)`: Checks if a token exists.

## Usage

To use this contract, deploy it to an Ethereum network, and then interact with it through the available functions to manage service NFTs, handle payments, and update service details.

### Example

```solidity
// Deploy the contract
SmartPosluhaNFT smartPosluha = new SmartPosluhaNFT("https://initial.offer.link");

// Add a new service type
smartPosluha.addServiceType(
    "Service Name",
    "Service Description",
    "https://image.link",
    30 days,
    100 * 10**18,
    0xTokenAddress,
    7 days
);

// Mint a new service NFT
uint256 tokenId = smartPosluha.mintServiceNFT(0xRecipientAddress, 0);

// Pay for the service
smartPosluha.payForService(tokenId);
```

Ensure to have the required permissions and token balances when interacting with the contract functions.
