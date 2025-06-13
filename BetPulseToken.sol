// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBTP {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BTPBetting {
    address public admin;
    address public treasury;
    IBTP public btp;
    uint256 public feePercent = 5;

    struct Bet {
        address player1;
        address player2;
        uint256 amount;
        bool accepted;
        bool resolved;
        address winner;
    }

    mapping(uint256 => Bet) public bets;
    uint256 public betCount;

    constructor(address _btp, address _treasury) {
        admin = msg.sender;
        btp = IBTP(_btp);
        treasury = _treasury;
    }

    function createBet(uint256 _amount) external {
        require(_amount > 0, "Valor invalido");
        btp.transferFrom(msg.sender, address(this), _amount);

        bets[betCount] = Bet({
            player1: msg.sender,
            player2: address(0),
            amount: _amount,
            accepted: false,
            resolved: false,
            winner: address(0)
        });
        betCount++;
    }

    function acceptBet(uint256 _betId) external {
        Bet storage bet = bets[_betId];
        require(!bet.accepted, "Ja aceito");
        require(bet.player1 != msg.sender, "Mesmo jogador");

        btp.transferFrom(msg.sender, address(this), bet.amount);
        bet.player2 = msg.sender;
        bet.accepted = true;
    }

    function resolveBet(uint256 _betId, address _winner) external {
        require(msg.sender == admin, "Apenas admin");
        Bet storage bet = bets[_betId];
        require(bet.accepted && !bet.resolved, "Invalido");

        uint256 total = bet.amount * 2;
        uint256 fee = (total * feePercent) / 100;
        uint256 reward = total - fee;

        btp.transfer(_winner, reward);
        btp.transfer(treasury, fee);

        bet.resolved = true;
        bet.winner = _winner;
    }
}



