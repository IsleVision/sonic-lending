//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./SonkToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///@notice Main Sonk contract responsible for lending, collateralizing and borrowing
///@author John Nguyen (jooohn.eth)
contract ProtocolCore is Ownable{

    ///@notice events emitted after each action.
    event Lend(address indexed lender, uint amount);
    event WithdrawLend(address indexed lender,string token, uint amount);
    event ClaimYield(address indexed lender, uint amount);
    event Collateralize(address indexed borrower, uint amount);
    event WithdrawCollateral(address indexed borrower, uint amount);
    event Borrow(address indexed borrower, uint amount);
    event Repay(address indexed borrower, uint amount);
    event Liquidate(address liquidator, uint reward, address indexed borrower);

    ///@notice mappings needed to keep track of lending
    mapping(address => uint) public lendingBalance;
    mapping(address => uint) public sonkBalance;
    mapping(address => uint) public startTime;
    mapping(address => bool) public isLending;

    ///@notice mappings needed to keep track of collateral and borrowing
    mapping(address => uint) public collateralBalance;
    mapping(address => uint) public borrowBalance;
    mapping(address => bool) public isBorrowing;

    ///@notice declaring chainlink's price aggregator.
    AggregatorV3Interface internal priceFeed;

    ///@notice declaring token variables.
    IERC20 public immutable baseAsset;
    IERC20 public immutable ethAsset;
    SonkToken public immutable sonkToken;
    address public ethAggregatorAddress;
    address public sonicAggregatorAddress;

    ///@notice initiating tokens
    ///@param _baseAssetAddress address of base asset token
    ///@param _sonkAddress address of $FUSN token
    constructor(IERC20 _baseAssetAddress, IERC20 _ethAssetAddress, SonkToken _sonkAddress,address _ethAggregatorAddress,address _sonicAggregatorAddress) {
        baseAsset = _baseAssetAddress;
        ethAsset = _ethAssetAddress;
        sonkToken = _sonkAddress;
        ethAggregatorAddress = _ethAggregatorAddress;
        sonicAggregatorAddress = _sonicAggregatorAddress;
    }

    ///@notice checks if the borrow position has passed the liquidation point
    ///@dev added 'virtual' identifier for MockCore to override
    modifier passedLiquidation(address _borrower) virtual {
//        uint collatAssetPrice = getCollatAssetPrice('Sonic')/getCollatAssetPrice('ETH');
        require(getCollatAssetPrice(sonicAggregatorAddress)/getCollatAssetPrice(ethAggregatorAddress) * collateralBalance[_borrower]  <= calculateLiquidationPoint(_borrower), "Position can't be liquidated!");
        _;
    }

    ///@notice Function to get latest price of ETH in USD
    ///@return collatAssetPrice price of ETH in USD
    function getCollatAssetPrice(address aggregatorAddress ) public view returns(uint collatAssetPrice){
        (,int price,,,) = AggregatorV3Interface(aggregatorAddress).latestRoundData();
        collatAssetPrice = uint(price);
    }

    ///@notice calculates amount of time the lender has been lending since the last update.
    ///@param _lender address of lender
    ///@return lendingTime amount of time staked by lender
    function calculateYieldTime(address _lender) public view returns(uint lendingTime) {
        lendingTime = block.timestamp - startTime[_lender];
    }

    ///@notice calculates amount of $FUSN tokens the lender has earned since the last update.
    ///@dev rate = timeStaked / amount of time needed to earn 100% of $FUSN tokens. 31536000 = number of seconds in a year.
    ///@param _lender address of lender
    ///@return yield amount of $FUSN tokens earned by lender
    function calculateYieldTotal(address _lender) public view returns(uint yield) {
        uint timeStaked = calculateYieldTime(_lender) ;
        yield = lendingBalance[_lender] * timeStaked / 31536000;
    }

    ///@notice calculates the borrow limit depending on the price of ETH and borrow limit rate.
    ///@return limit current borrow limit for user
    function calculateBorrowLimit(address _borrower) public view returns(uint limit) {
//        uint collatAssetPrice = getCollatAssetPrice('Sonic')/getCollatAssetPrice('ETH');
        limit = ((((getCollatAssetPrice(sonicAggregatorAddress)/getCollatAssetPrice(ethAggregatorAddress) * collateralBalance[_borrower]) * 70) / 100)) - borrowBalance[_borrower];
    }

    function calculateLiquidationPoint(address _borrower) public view returns(uint point) {
        point = borrowBalance[_borrower] + (borrowBalance[_borrower] * 10) / 100;
    }

    ///@notice lends base asset.
    ///@param _amount amount of tokens to lend
    function lend(uint _amount) external {
        require(_amount > 0, "Can't lend amount: 0!");
        require(baseAsset.balanceOf(msg.sender) >= _amount, "Insufficient balance!");

        if(isLending[msg.sender]) {
            uint yield = calculateYieldTotal(msg.sender);
            sonkBalance[msg.sender] += yield;
        }

        lendingBalance[msg.sender] += _amount;
        startTime[msg.sender] = block.timestamp;
        isLending[msg.sender] = true;

//        baseAsset.approve(address (this), _amount);
        require(baseAsset.transferFrom(msg.sender, address(this), _amount), "Transaction failed!");

        emit Lend(msg.sender, _amount);
    }

    ///@notice withdraw base asset.
    ///@param _amount amount of tokens to withdraw
    function withdrawLend(uint _amount) public {
        require(isLending[msg.sender], "Can't withdraw before lending!");
        require(lendingBalance[msg.sender] >= _amount, "Insufficient lending balance!");

        uint yield = calculateYieldTotal(msg.sender);
        sonkBalance[msg.sender] += yield;
        startTime[msg.sender] = block.timestamp;

        uint withdrawAmount = _amount;
        _amount = 0;
        lendingBalance[msg.sender] -= withdrawAmount;

        if(lendingBalance[msg.sender] == 0){
            isLending[msg.sender] = false;
        }

        if(baseAsset.balanceOf(address(this)) >= withdrawAmount){
            require(baseAsset.transfer(msg.sender, withdrawAmount), "Transaction failed!");
            emit WithdrawLend(msg.sender, 'S',withdrawAmount);
        }
        else {
            //when the amount of base asset is not enough, we need to convert to ETH
            withdrawAmount = getCollatAssetPrice(ethAggregatorAddress)/getCollatAssetPrice(sonicAggregatorAddress)*withdrawAmount;
            require(ethAsset.transfer(msg.sender, withdrawAmount), "No sufficient fund in the pool!");
            emit WithdrawLend(msg.sender, 'ETH',withdrawAmount);
        }

    }
    
    ///@notice claims all yield earned by lender.
    function claimYield() external {
        uint yield = calculateYieldTotal(msg.sender);

        require(yield > 0 || sonkBalance[msg.sender] > 0, "No, $Sonk tokens earned!");

        if(sonkBalance[msg.sender] != 0) {
            uint oldYield = sonkBalance[msg.sender];
            sonkBalance[msg.sender] = 0;
            yield += oldYield;
        }

        startTime[msg.sender] = block.timestamp;
        sonkToken.mint(msg.sender, yield);

        emit ClaimYield(msg.sender, yield);
    }

    ///@notice collateralizes user's ETH and sets borrow limit
    function collateralize(uint _amount) external payable {
        require(_amount > 0, "Can't collaterlize ETH amount: 0!");
        require(ethAsset.balanceOf(msg.sender) >= _amount, "Insufficient balance!");

        collateralBalance[msg.sender] += _amount;

//        ethAsset.approve(address(this), _amount);
        require(ethAsset.transferFrom(msg.sender, address(this), _amount), "Transaction failed!");
        emit Collateralize(msg.sender, _amount);
    }

    ///@notice withdraw user's collateral ETH and recalculates the borrow limit
    ///@param _amount amount of ETH the user wants to withdraw
    function withdrawCollateral(uint _amount) external {
        require(collateralBalance[msg.sender] >= _amount, "Not enough collateral to withdraw!");
        require(!isBorrowing[msg.sender], "Can't withdraw collateral while borrowing!");

        collateralBalance[msg.sender] -= _amount;

        require(ethAsset.transfer(msg.sender, _amount), "Transaction failed!");
        emit WithdrawCollateral(msg.sender, _amount);
    }

    ///@notice borrows base asset
    ///@param _amount amount of base asset to borrow
    ///@dev deducting 0.3% from msg.sender's ETH collateral as protocol's fees
    function borrow(uint _amount) external {
        collateralBalance[msg.sender] -= (collateralBalance[msg.sender] * 3) / 1000;

        require(collateralBalance[msg.sender] > 0, "No ETH collateralized!");
        require(calculateBorrowLimit(msg.sender) >= _amount, "Borrow amount exceeds borrow limit!");

        isBorrowing[msg.sender] = true;
        borrowBalance[msg.sender] += _amount;

        require(baseAsset.transfer(msg.sender, _amount), "Transaction failed!");

        emit Borrow(msg.sender, _amount);
    }
    
    ///@notice repays base asset debt
    ///@param _amount amount of base asset to repay
    function repay(uint _amount) external {
        require(isBorrowing[msg.sender], "Can't repay before borrowing!");
        require(baseAsset.balanceOf(msg.sender) >= _amount, "Insufficient funds!");
        require(_amount > 0 , "Can't repay amount 0!");
        require(_amount <= borrowBalance[msg.sender], "Can't repay amount more than borrowed!");

        if(_amount == borrowBalance[msg.sender]){ 
            isBorrowing[msg.sender] = false;
        }

        borrowBalance[msg.sender] -= _amount;

//        baseAsset.approve(address (this), _amount);
        require(baseAsset.transferFrom(msg.sender, address(this), _amount), "Transaction Failed!");

        emit Repay(msg.sender, _amount);
    }

    ///@notice liquidates a borrow position
    ///@param _borrower address of borrower
    ///@dev passedLiquidation modifier checks if the borrow position has passed liquidation point
    ///@dev liquidationReward 1.25% of borrower's ETH collateral
    function liquidate(address _borrower) external onlyOwner passedLiquidation(_borrower) {
        require(isBorrowing[_borrower], "This address is not borrowing!");
        require(msg.sender != _borrower, "Can't liquidated your own position!");    

        uint liquidationReward = (collateralBalance[_borrower] * 125) / 10000; 

        collateralBalance[_borrower] = 0;
        borrowBalance[_borrower] = 0;
        isBorrowing[_borrower] = false;

        require(ethAsset.transfer(msg.sender, liquidationReward), "Transaction failed!");

//        (bool success, ) = msg.sender.call{value: liquidationReward}("");
//        require(success, "Transaction Failed!");

        emit Liquidate(msg.sender, liquidationReward, _borrower);
    }

    ///@notice returns lending status of lender
    function getLendingStatus(address _lender) external view returns(bool){
        return isLending[_lender];
    }  

    ///@notice retuns amount of $FUSN tokens earned
    function getEarnedSonkTokens(address _lender) external view returns(uint){
        return sonkBalance[_lender] + calculateYieldTotal(_lender);
    }

    ///@notice returns amount of base asset lent
    function getLendingBalance(address _lender) external view returns(uint){
        return lendingBalance[_lender];
    }

    ///@notice returns amount of collateralized asset
    function getCollateralBalance(address _borrower) external view returns(uint){
        return collateralBalance[_borrower];
    }


    ///@notice returns borrowing status of borrower
    function getBorrowingStatus(address _borrower) external view returns(bool){
        return isBorrowing[_borrower];
    }

    ///@notice returns amount of base asset borrowed
    function getBorrowBalance(address _borrower) external view returns(uint){
        return borrowBalance[_borrower];
    }

    ///@notice returns amount of base asset available to borrow
    function getBorrowLimit(address _borrower) external view returns(uint){
        return calculateBorrowLimit(_borrower);
    }

    ///@notice returns liquidation point
    function getLiquidationPoint(address _borrower) external view returns(uint){
        return calculateLiquidationPoint(_borrower);
    }
}