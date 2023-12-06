// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../GasRelayer.sol";

contract GasRelayerMock is GasRelayer {
    constructor(
        address endpoint,
        uint256 protocolFee,
        ISwapRouter router_,
        IWETH weth_,
        address wethPriceFeed,
        uint256 maxDiscount_
    )  GasRelayer(endpoint, protocolFee, router_, weth_, wethPriceFeed, maxDiscount_) {}

    // *
    //  A mock receive function, used to test side effects of the relay function
    // *
    function nonblockingLzReceiveMock(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external {
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
}