// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./lzApp/NonblockingLzApp.sol";
import "./ERC20Swap.sol";

contract GasRelayer is NonblockingLzApp, ERC20Swap {
    event GasReceived(address indexed sender, uint16 srcChainId);
    event GasSent(address indexed sender, uint16 destChainId);

    uint256 internal _protocolFee;

    constructor(
        address endpoint,
        uint256 protocolFee,
        ISwapRouter router_,
        IWETH weth_,
        address wethPriceFeed,
        uint256 maxDiscount_
    ) NonblockingLzApp(endpoint) ERC20Swap(router_, weth_, wethPriceFeed, maxDiscount_) {
        _protocolFee = protocolFee;
    }

    // *
    // Send and receive gas
    // *

    function relay(uint16 destChainId) public payable {
        require(msg.value > _protocolFee, "GasRelayer: not enough gas for fees");
        bytes memory adapterParams = _relayAdapterParams(msg.sender);
        _lzSend(
            destChainId,
            abi.encode(msg.sender),
            payable(address(msg.sender)),
            address(0x0),
            adapterParams,
            msg.value - _protocolFee
        );
        emit GasSent(msg.sender, destChainId);
    }

    function relayWithERC20(uint16 destChainId, address token) external onlyWhitelist(token) {
        // get the total fee in ETH for gas relay)
        uint256 fee = estimateFeeRelay(destChainId, msg.sender);

        // purchase ETH with the ERC20 token
        _swapExactInToWETH(token, fee);

        // send the ETH to the destination chain
        relay(destChainId);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory /*_srcAddress*/,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal override {
        address sender = abi.decode(_payload, (address));
        emit GasReceived(sender, _srcChainId);
    }

    // *
    // Fee estimation
    // *

    function estimateFeeRelay(uint16 destChainId, address destinationAddress) public view returns (uint256) {
        bytes memory adapterParams = _relayAdapterParams(destinationAddress);
        (uint nativeFee,) = lzEndpoint.estimateFees(destChainId, address(this), abi.encode(destinationAddress), false, adapterParams);
        return nativeFee + _protocolFee;
    }

    function estimateFeeRelayWithERC20(uint16 destChainId, address destinationAddress, address token) external view onlyWhitelist(token) returns (uint256) {
        uint256 fee = estimateFeeRelay(destChainId, destinationAddress);
        return _maximumAmountIn(token, fee);
    }

    // *
    // Internal functions
    // *

    function _relayAdapterParams(address destinationAddress) internal pure returns (bytes memory) {
        uint16 version = 2;
        uint256 gasForDestinationReceive = 350_000;
        // TODO: make this configurable
        uint256 destinationAirdrop = 500_000;
        return abi.encodePacked(
            version,
            gasForDestinationReceive,
            destinationAirdrop,
            destinationAddress
        );
    }

    // *
    // Setters and getters
    // *

    function setProtocolFee(uint256 protocolFee) external onlyOwner {
        _protocolFee = protocolFee;
    }

    function getProtocolFee() external view returns (uint256) {
        return _protocolFee;
    }

    // *
    // Privileged functions
    // *

    // owner can withdraw accrued protocol fees
    function withdraw(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    // owner can add an ERC20 token to the whitelist
    function addToWhitelist(address asset, address datafeed) external onlyOwner {
        _addToWhitelist(asset, datafeed);
    }

    // owner can remove an ERC20 token from the whitelist
    function removeFromWhitelist(address asset) external onlyOwner {
        _removeFromWhitelist(asset);
    }

    // owner can set the maximum discount for ERC20 swaps
    // this gives some leeway in case the price feed is slightly off
    // from what Uniswap is offering
    function setMaxDiscount(uint256 discount) external onlyOwner {
        _setMaxDiscount(discount);
    }

    // receive necessary for ERC20 swaps
    receive() external payable {}

}