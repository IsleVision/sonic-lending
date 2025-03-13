# Sonk

### Build on top of [Fusion Finance](https://github.com/jooohneth/fusion-finance)

## Tokens Information

### Sonic

-  WETH
-  WS
-  Sonk

## Overview

A decentralized lending and borrowing protocol for users to lend and borrow Sonic Asset. A completely trustless environment for both lenders and borrowers, built on top of Ethereum solutions. Lenders supply the protocol with Sonic Asset and in return earn interest in a form of $Sonk tokens, protocol’s governance token. Thanks to lenders, our protocol will have liquidity to supply the borrowers with Sonic Asset. In order for borrowers to borrow they will have to collateralize WETH, our protocol works in an over-collateralized model, meaning borrower’s WETH collateral amount > Sonic Asset amount they can borrow. The borrowers pay interest to the protocol in order to maintain it, the interest will be deducted from WETH collateral when the borrower borrows Sonic Asset. In case of liquidation, our protocol keeps the borrower's WETH collateral and rewards the liquidator.

## Deliverables

### Web App:

- Collateralize WETH
- Withdraw Sonic Asset
- Repay Sonic Asset
- Explore the following information:
  - Protocol’s name
  - User’s wallet address.
  - User’s WETH and $Sonk balance.
  - Sonic Asset % APY
  - Current supplied or borrowed amounts, if any.

### Smart-contracts:

- ProtocolCore contract:

  - Mapping of lender to amount of Sonic Asset provided.
  - Mapping of lender to amount of $Sonk earned.
  - Mapping of borrower to amount of Sonic Asset borrowed.
  - Mapping of borrower to amount of WETH collateralized.
  - Lend function - saves earned $Sonk amount, if any => updates lend position state => sends user’s provided amount of Sonic Asset to the protocol.
  - Lender’s withdrawal function - saves amount of $Sonk earned, if any => resets lend position state => sends WETH to protocol.
  - Claim Yield function - calculates earned $Sonk yield => mints the lender the amount.
  - Collateralize WETH function - updates collateral position => sends WETH to protocol.
  - Withdraw WETH function(Can’t be called while borrowing) - updates collateral position => sends WETH to user.
  - Borrow function(Only if WETH is collateralized) - deduct protocol’s fees (0.3%) => updates borrow position => sends the user amount of Sonic Asset provided inside the borrow limit.
  - Borrower’s repay function - updates borrow position state => sends Sonic Asset from borrower to protocol.
  - Liquidate function(any user including the deployer can execute a liquidation function) - check if the liquidation point has been passed => liquidate borrower’s position => send the liquidator liquidation reward (1.25%) of borrower’s WETH collateral as reward.
  - Calculate Price of WETH function - Using Chainlink’s price oracle calculates and returns the price of WETH in Sonic Asset.
  - Calculate Yield Time - calculates the amount of time the lender has been lending.
  - Calculate Yield Total - calculates the amount of $Sonk tokens the lender has earned.
  - Calculate Borrow limit function - get the price of WETH from Chainlink's price feed
  - Sonic Asset => (WETH price _ WETH collateral) _ borrow rate (70%) - borrower’s amount of borrowed Sonic Asset, if any .
  - Calculate Liquidation point - get the price of WETH in Sonic Asset => amount of borrowed Sonic Asset + liquidation rate (10%).

- SonkToken ($Sonk) contract:

  - Type - ERC20 token
  - Purpose - Mints tokens to lenders as reward.
