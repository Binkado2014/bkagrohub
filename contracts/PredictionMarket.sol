// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PredictionMarket {
    struct Market {
        uint256 id;
        string question;
        uint256 endTime;
        bool resolved;
        bool outcome; // true = Yes, false = No
        uint256 totalYes;
        uint256 totalNo;
        address creator;
    }

    struct Bet {
        uint256 yesAmount;
        uint256 noAmount;
        bool claimed;
    }

    uint256 public marketCount;
    mapping(uint256 => Market) public markets;
    mapping(uint256 => mapping(address => Bet)) public bets;
    address public oracle;

    event MarketCreated(uint256 id, string question, uint256 endTime, address creator);
    event BetPlaced(uint256 marketId, address user, bool isYes, uint256 amount);
    event MarketResolved(uint256 marketId, bool outcome);
    event WinningsClaimed(uint256 marketId, address user, uint256 amount);

    constructor() {
        oracle = msg.sender; // For MVP, deployer acts as the resolution oracle
    }

    function createMarket(string memory _question, uint256 _durationInSeconds) external {
        require(_durationInSeconds > 0, "Duration must be > 0");
        uint256 endTime = block.timestamp + _durationInSeconds;
        
        markets[marketCount] = Market({
            id: marketCount,
            question: _question,
            endTime: endTime,
            resolved: false,
            outcome: false,
            totalYes: 0,
            totalNo: 0,
            creator: msg.sender
        });

        emit MarketCreated(marketCount, _question, endTime, msg.sender);
        marketCount++;
    }

    function betYes(uint256 _marketId) external payable {
        Market storage market = markets[_marketId];
        require(block.timestamp < market.endTime, "Market ended");
        require(!market.resolved, "Market already resolved");
        require(msg.value > 0, "Bet amount must be > 0");

        market.totalYes += msg.value;
        bets[_marketId][msg.sender].yesAmount += msg.value;

        emit BetPlaced(_marketId, msg.sender, true, msg.value);
    }

    function betNo(uint256 _marketId) external payable {
        Market storage market = markets[_marketId];
        require(block.timestamp < market.endTime, "Market ended");
        require(!market.resolved, "Market already resolved");
        require(msg.value > 0, "Bet amount must be > 0");

        market.totalNo += msg.value;
        bets[_marketId][msg.sender].noAmount += msg.value;

        emit BetPlaced(_marketId, msg.sender, false, msg.value);
    }

    function resolveMarket(uint256 _marketId, bool _outcome) external {
        require(msg.sender == oracle, "Only oracle can resolve");
        Market storage market = markets[_marketId];
        require(block.timestamp >= market.endTime, "Market not ended yet");
        require(!market.resolved, "Market already resolved");

        market.resolved = true;
        market.outcome = _outcome;

        emit MarketResolved(_marketId, _outcome);
    }

    function claimWinnings(uint256 _marketId) external {
        Market storage market = markets[_marketId];
        require(market.resolved, "Market not resolved");
        
        Bet storage userBet = bets[_marketId][msg.sender];
        require(!userBet.claimed, "Already claimed");

        uint256 reward = 0;
        uint256 totalPool = market.totalYes + market.totalNo;

        if (market.outcome == true && userBet.yesAmount > 0) {
            // Yes won: proportional share of total pool
            reward = (userBet.yesAmount * totalPool) / market.totalYes;
        } else if (market.outcome == false && userBet.noAmount > 0) {
            // No won: proportional share of total pool
            reward = (userBet.noAmount * totalPool) / market.totalNo;
        }

        require(reward > 0, "No winnings to claim");

        userBet.claimed = true;
        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Transfer failed");

        emit WinningsClaimed(_marketId, msg.sender, reward);
    }

    // Helper for frontend to fetch multiple markets efficiently
    function getMarkets(uint256 cursor, uint256 count) external view returns (Market[] memory, uint256) {
        uint256 length = count;
        if (cursor + length > marketCount) {
            length = marketCount - cursor;
        }
        Market[] memory result = new Market[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = markets[cursor + i];
        }
        return (result, cursor + length);
    }
}
