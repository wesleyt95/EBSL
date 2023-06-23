// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Uncomment this line to use console.log

contract Bet {
    struct Transaction  {
        address addr;
        uint amount;
        uint team;
    }
    struct MoneyLine {
        uint total;
        mapping(uint => uint) teamTotal;
        uint homeTeamID;
        uint awayTeamID;
        address[] awayArray;
        address[] homeArray;
        mapping(address => Transaction) receipt;
        uint winner;
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

    mapping(address => uint) public balances;
    mapping(uint256 => MoneyLine) public newMoneyLineBet;
    mapping(uint256 => uint256) public totalBetOnGame;
    mapping(uint256 => mapping(uint256 => uint256)) public totalBetOnTeam;

function returnOdds(uint256 gameID, uint256 bettingTeamID, uint256 opposingTeamID) public view returns (uint256) {
    return totalBetOnTeam[gameID][bettingTeamID] / (totalBetOnTeam[gameID][bettingTeamID] + totalBetOnTeam[gameID][opposingTeamID]);
}
function moneyLineBetCalculator(uint256 gameID, uint256 teamID, uint256 opposingTeamID, uint256 amount) public payable returns (uint256) {
     uint256 currentTotal = newMoneyLineBet[gameID].teamTotal[teamID];
    uint256 exampleNewTotal = currentTotal + amount;
    uint256 payout = (amount/exampleNewTotal) * (exampleNewTotal + newMoneyLineBet[gameID].teamTotal[opposingTeamID]);
    return payout;
}
function moneyLineBet(uint256 gameID, uint256 teamID, uint256 homeTeamID, uint256 awayTeamID) public payable returns (uint256) {
    require(msg.value > 0, "You must bet something");
    require(teamID == homeTeamID || teamID == awayTeamID, "You must bet on a team that is playing in this game");
    uint256 currentGameTotal = totalBetOnGame[gameID];
    uint256 currentGameTotalTeam = totalBetOnTeam[gameID][teamID];
    uint256 currentTeamTotal = newMoneyLineBet[gameID].teamTotal[teamID];
    uint256 currentTotal = newMoneyLineBet[gameID].total;

    totalBetOnGame[gameID] = currentGameTotal + msg.value;
    totalBetOnTeam[gameID][teamID] = currentGameTotalTeam + msg.value;
    newMoneyLineBet[gameID].total =  currentTotal + msg.value;
    newMoneyLineBet[gameID].teamTotal[teamID] = currentTeamTotal + msg.value;
    newMoneyLineBet[gameID].homeTeamID = homeTeamID;
    newMoneyLineBet[gameID].awayTeamID = awayTeamID;
    newMoneyLineBet[gameID].receipt[msg.sender] = Transaction(msg.sender, msg.value, teamID);

    if (teamID == homeTeamID) {
        newMoneyLineBet[gameID].homeArray.push(msg.sender);
        
    } else {
        newMoneyLineBet[gameID].awayArray.push(msg.sender);
    }
   
    return 0;
}




}