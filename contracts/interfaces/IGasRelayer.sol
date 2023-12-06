// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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