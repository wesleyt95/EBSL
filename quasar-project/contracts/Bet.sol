// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Uncomment this line to use console.log

contract Bet {
    struct User {
        uint256 escrow;
        Transaction[] receipt;
    }
    struct Transaction  {
        address addr;
        uint256 amount;
        uint256 teamID;
        uint256 gameID;
    }
    struct MoneyLine {
        uint256 total;
        mapping(uint => uint) teamTotal;
        uint256 homeTeamID;
        uint256 awayTeamID;
        address[] awayArray;
        address[] homeArray;
        mapping(uint256 => mapping(address => Transaction)) receipt;
        uint256 winner;
    }
     struct PointTotal {
        uint MoneyLine;
        uint pointTotal;
        uint pointSpread;
        mapping(uint  => mapping(string => Transaction[])) funders;
    }
     struct PointSpread {
        uint MoneyLine;
        uint pointTotal;
        uint pointSpread;
        mapping(uint => mapping(string => Transaction[])) funders;
    }

    mapping(address => User) public balances;
    mapping(uint256 => MoneyLine) public newMoneyLineBet;
    mapping(uint256 => uint256) public totalBetOnGame;
    mapping(uint256 => mapping(uint256 => uint256)) public totalBetOnTeam;

    function returnOdds(uint256 gameID, uint256 bettingTeamID, uint256 opposingTeamID) public view returns (uint256) {
        return totalBetOnTeam[gameID][bettingTeamID] / (totalBetOnTeam[gameID][bettingTeamID] + totalBetOnTeam[gameID][opposingTeamID]);
    }
    function moneyLineBet(uint256 gameID, uint256 teamID, uint256 homeTeamID, uint256 awayTeamID) public payable {
        require(msg.value > 0, "You must bet something");
        require(teamID == homeTeamID || teamID == awayTeamID, "You must bet on a team that is playing in this game");
        totalBetOnGame[gameID] += msg.value;
        totalBetOnTeam[gameID][teamID] += msg.value;
        newMoneyLineBet[gameID].total += msg.value;
        newMoneyLineBet[gameID].teamTotal[teamID] += msg.value;
        newMoneyLineBet[gameID].homeTeamID = homeTeamID;
        newMoneyLineBet[gameID].awayTeamID = awayTeamID;
        newMoneyLineBet[gameID].receipt[teamID][msg.sender] = Transaction(msg.sender, msg.value, teamID, gameID);
        balances[msg.sender].escrow += msg.value;
        balances[msg.sender].receipt.push(Transaction(msg.sender, msg.value, teamID, gameID));
        if (teamID == homeTeamID) {
            newMoneyLineBet[gameID].homeArray.push(msg.sender);
        } else {
            newMoneyLineBet[gameID].awayArray.push(msg.sender);
        }
       
    }

    function returnMoneyLineBetReceipt(uint256 gameID, uint256 teamID) public view returns (Transaction memory) {
        return newMoneyLineBet[gameID].receipt[teamID][msg.sender];
    }

    function returnEscrow() public view returns (uint256) {
        return balances[msg.sender].escrow;
    }

    function returnReceipts() public view returns (Transaction[] memory) {
        return balances[msg.sender].receipt;
    }
}