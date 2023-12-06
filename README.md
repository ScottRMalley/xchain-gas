# XChain Gas Provider

The purpose of these contracts is to make use of LayerZero's airdrop functionality to allow users to buy gas
on any supported chain. By simply calling `relay(targetChainId)` a small amount of gas can be transferred from the
user's wallet on the current chain to the user's wallet on the target chain.

**NOTE:** These contracts are for illustrative purposes only and are not intended to be used in production.

## Interfaces
The primary magic happens in the `GasRelayer` contract. This contract is responsible for relaying gas from the current
chain to the target chain. Note that users have to pay to call this contract, but not to receive the funds on the
target chain.

```solidity
interface IGasRelayer {
    // sends a fixed amount of gas to the destination chain
    function relay(uint16 destChainId) public payable;

    // buys gas with an erc20 token and sends it to the destination chain
    function relayWithERC20(uint16 destChainId, address token) external;

    // estimate the total fee to send gas to the destination chain
    function estimateFeeRelay(uint16 destChainId, address destinationAddress) external view returns (uint256);

    // estimate the total fee to send gas to the destination chain paying in ERC20 token
    function estimateFeeRelayWithERC20(uint16 destChainId, address destinationAddress, address token) external view returns (uint256);

    // returns the protocol fee (a fixed fee for every gas relay)
    function getProtocolFee() external view returns (uint256);
}
```

## Under the hood

LayerZero is a popular cross chain general purpose messaging service. As part of each message sent from one chain to
another, a small amount of gas can be airdropped to any address on the target chain. At the base level, these 
contracts just wrap that functionality so that a user doesn't have to make use of another service (such as Stargate),
if all they want is a little gas to make a transfer. For this basic example, the airdropped amount is just hard coded:
```solidity
uint16 version = 2;
uint256 gasForDestinationReceive = 350_000;
// TODO: make this configurable
uint256 destinationAirdrop = 500_000;
bytes memory params = abi.encodePacked(
    version,
    gasForDestinationReceive,
    destinationAirdrop,
    destinationAddress
);
```

On top of this functionality, these contracts also allow users to pay for the LayerZero transaction fee and airdrop 
fee using whitelisted ERC20 addresses. The reason a whitelist is necessary here is that in order to be able to pay 
in ERC20 tokens, we need to be able to trade the specific ERC20 token for native Ether. This requires:
* A DEX that supports the ERC20 token and has enough liquidity to make the trade
* A Chainlink price feed for the ERC20 token that can used to estimate how much of the token is needed to pay for the
  transaction fee and airdrop fee (and to prevent frontrunning).

Only the contract owner can whitelist ERC20 tokens. This means that the contracts themselves have a few permissioned 
functions:
```solidity
// owner can withdraw accrued protocol fees
function withdraw(address payable to) external onlyOwner;

// owner can add an ERC20 token to the whitelist
function addToWhitelist(address asset, address datafeed) external onlyOwner;

// owner can remove an ERC20 token from the whitelist
function removeFromWhitelist(address asset) external onlyOwner;

// owner can set the maximum discount for ERC20 swaps
// this gives some leeway in case the price feed is slightly off
// from what Uniswap is offering
function setMaxDiscount(uint256 discount) external onlyOwner;
```

The contracts also have the ability to charge a small fee for each gas relay. This fee is currently set to a fixed 
amount of Wei, but can be updated by the contract owner after deployment. The protocol fee is included in the 
`estimateFee` functions that should be called before use.

## Usage

### Deploying the contracts
The contracts can be deployed using `hardhat-deploy` plugin:
```shell
npx hardhat deploy --network <network>
```

### Testing the contracts
The contracts can be tested using `hardhat`:
```shell
npx hardhat test
```
**NOTE:** The tests are not currently extensive. In order to properly test the ERC20 swapping functionality, the 
tests need to be reconfigured to run on a local fork of mainnet. This would allow the price feed and Uniswap pairs 
to be functional.

## Dependencies
* [LayerZero](https://layerzero.gitbook.io/docs/) - LayerZero unfortunately does not have a functional Solidity 
  library at the time of writing,  so several of the contracts in this repo are copied from the LayerZero 
  recommended usage.
* [Uniswap Contracts](https://docs.uniswap.org/contracts/v3/overview) - The Uniswap contracts are used to swap ERC20 
  tokens for native Ether.
* [Chainlink Contracts](https://www.npmjs.com/package/@chainlink/contracts) - The Chainlink contracts are used to 
  estimate the price of ERC20 tokens.
* [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/5.x/) - The OpenZeppelin contracts are used for 
  several utility functions.