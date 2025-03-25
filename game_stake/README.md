# PredicX: A Decentralized Prediction Market

## Overview
PredicX is a blockchain-based prediction market platform where users can stake tokens and make predictions on various market events. The platform ensures fair competition, rewards accurate predictions, and fosters engagement through progressive challenges and incentives. Built on the Clarity smart contract language, PredicX guarantees transparency, security, and immutability.

## Features
- **Decentralized Market**: Fully on-chain prediction markets where users stake and win rewards.
- **Progressive Market Challenges**: Users progress through different levels as they successfully predict market outcomes.
- **Automated Rewards Distribution**: Smart contract-enforced staking and reward mechanisms ensure fair payouts.
- **Top Predictor Leaderboard**: Recognition and ranking system for high-performing predictors.
- **Transparent Market Resolution**: Immutable rules define market conditions and outcomes.

## Smart Contract Functionalities
### Constants
The contract defines error constants for various failure conditions such as unauthorized access, invalid markets, insufficient stake, and incorrect predictions.

### Data Variables
- **platform-admin**: Stores the administrator's principal address.
- **platform-active**: Boolean flag indicating whether the platform is live.
- **current-market-id**: Tracks the latest market ID.
- **market-entry-stake**: Defines the STX required for market entry.
- **total-market-pool**: Tracks the total STX pooled in the system.
- **max-market-reward**: Caps the reward for any single market.

### Maps
- **prediction-markets**: Stores active markets with their descriptions, deadlines, and rewards.
- **predictor-progress**: Tracks the progress of individual users in the system.
- **market-predictions**: Stores prediction history for users and markets.
- **market-top-predictors**: Lists top predictors for each market.

## Contract Functions
### Platform Management
- **initialize-prediction-platform**: Activates the platform and resets tracking variables.
- **create-prediction-market**: Admin function to create a new prediction market with a reward.

### User Functions
- **register-predictor**: Allows users to register by staking the required entry fee.
- **submit-prediction**: Enables users to submit predictions for a specific market.

### Read-Only Functions
- **get-current-market-details**: Retrieves details of an active market.
- **get-predictor-status**: Returns a predictor’s current progress.
- **get-market-top-predictors**: Lists the top predictors for a given market.
- **get-platform-stats**: Fetches general statistics of the platform.

## How It Works
1. **Platform Activation**: The admin initializes the platform.
2. **Market Creation**: The admin creates prediction markets with deadlines and rewards.
3. **User Registration**: Users register by staking tokens.
4. **Prediction Submission**: Users submit predictions before the deadline.
5. **Market Resolution**: The platform verifies outcomes and distributes rewards.
6. **Leaderboard Updates**: Top predictors are recorded and ranked.

## Deployment
PredicX is designed for the Stacks blockchain using Clarity smart contracts. To deploy:
1. Install the Stacks CLI.
2. Clone the repository.
3. Compile and deploy the contract using `clarity-cli`.

## Contributing
Contributions are welcome! Submit a pull request or open an issue to discuss improvements.
