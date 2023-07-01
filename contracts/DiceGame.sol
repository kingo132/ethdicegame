// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Strings.sol";

contract DiceGame {
    enum BetType { SMALL, BIG }

    struct Player {
        uint256 betAmount;
        BetType betType;
    }

    address public banker;
    uint256 public bankerDeposit;
    uint256 public roundStart;
    uint256 public bankerSettledTime;
    mapping(address => Player) public players;
    address[10] public playerAddresses;
    uint256 public playerCount = 0;

    event NewBanker(address indexed banker, uint256 deposit);
    event NewBet(address indexed player, uint256 amount, BetType betType);
    event RollResult(uint256 result, BetType resultType);

    modifier onlyBanker() {
        require(msg.sender == banker, "Only banker can perform this action");
        _;
    }

    modifier onlyDuringBetting() {
        require(banker != address(0), "Banker is not settled yet");
        _;
    }

    function becomeBanker() external payable {
        require(msg.value >= 0.04 ether, "Deposit must be at least 4 Ether");

        if (banker != address(0)) {
            require(block.timestamp < roundStart + 30 seconds, "become banker period is over");
            require(msg.value > bankerDeposit, "Must deposit more than current banker");

            // Refund the previous banker
            address(uint160(banker)).transfer(bankerDeposit);
        } else {
            roundStart = block.timestamp; // Start the round
            bankerSettledTime = block.timestamp + 30 seconds; // Banker will be settled in 30 seconds
        }

        banker = msg.sender;
        bankerDeposit = msg.value;

        emit NewBanker(banker, bankerDeposit);
    }

    function bet(BetType betType) external payable onlyDuringBetting {
        require(msg.value <= 0.001 ether, "Bet must be less than or equal to 1 Ether");
        require(playerCount < 10, "There are already 10 players");
        require(msg.sender != banker, "Banker cannot bet");
        require(players[msg.sender].betAmount == 0, "Player has already bet");

        players[msg.sender] = Player({
            betAmount: msg.value,
            betType: betType
        });

        playerAddresses[playerCount] = msg.sender;
        playerCount++;

        emit NewBet(msg.sender, msg.value, betType);
    }

    function rollDice() external onlyBanker {
        require(playerCount >= 1, "At least need 1 player");
        uint256 result = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 6 + 1;

        BetType resultType = result <= 3 ? BetType.SMALL : BetType.BIG;

        for (uint256 i = 0; i < playerCount; i++) {
            address playerAddress = playerAddresses[i];
            Player storage player = players[playerAddress];

            if (player.betType == resultType) {
                address(uint160(playerAddress)).transfer(player.betAmount * 2);
                bankerDeposit -= player.betAmount * 2;
            } else {
                //address(uint160(banker)).transfer(player.betAmount);
                bankerDeposit += player.betAmount;
            }

            // Reset the player
            delete players[playerAddress];
        }

        // Reset the game
        playerCount = 0;

        emit RollResult(result, resultType);

        // revoke the banker if deposit is not enough
        if (bankerDeposit < 0.04 ether) {
            address(uint160(banker)).transfer(bankerDeposit);
            bankerDeposit = 0;
            banker = address(0);
        }
    }

    function checkBankerSettled() external {
        //require(block.timestamp >= bankerSettledTime, string(abi.encodePacked(Strings.toString(block.timestamp), " - ", Strings.toString(bankerSettledTime))));
        require(banker != address(0), "Banker is not settled yet");
    }

    function getCurrentBanker() public view returns (address) {
        return banker;
    }

    function getBankerDeposit() public view returns (uint) {
        return bankerDeposit;
    }
}
