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

