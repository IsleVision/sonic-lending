//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../ProtocolCore.sol";

///@notice Mock of ProtocolCore.sol contract for testing liquidate function
contract MockCore is ProtocolCore {

    constructor(IERC20 _baseAssetAddress, IERC20 _ethAssetAddress, SonkToken _sonkAddress, address _ethAggregatorAddress, address _sonicAggregatorAddress) ProtocolCore(_baseAssetAddress, _ethAssetAddress, _sonkAddress, _ethAggregatorAddress, _sonicAggregatorAddress){}

    ///@notice overriding the passedLiquidation modifier to mock the price of ETH. Let's anyone liquidate any borrow position.
    ///@dev ethPrice set to 0 to be able to get liquidated
    modifier passedLiquidation(address _borrower) override {
        uint ethPrice = 0;
        require((ethPrice * collateralBalance[_borrower]) <= calculateLiquidationPoint(_borrower), "Position can't be liquidated!");
        _;
    }

}