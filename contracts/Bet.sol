// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Bet {
  address payable admin;

  constructor() {
    admin = payable(msg.sender);
  }

  struct User {
    uint256 escrow;
    Transaction[] receipts;
  }
  struct Transaction {
    address addr;
    uint256 amount;
    uint256 teamID;
    uint256 gameID;
    string betType;
  }
  struct MoneyLine {
    uint256 startTime;
    uint256 total;
    mapping(uint256 => uint256) teamTotal;
    uint256 homeTeamID;
    uint256 awayTeamID;
    mapping(uint256 => address[]) usersArray;
    mapping(uint256 => mapping(address => Transaction)) receipt;
    uint256 result;
  }
  struct PointSpread {
    mapping(uint256 => int) spreadAmount;
    uint256 startTime;
    uint256 total;
    mapping(uint256 => uint256) teamTotal;
    uint256 homeTeamID;
    uint256 awayTeamID;
    mapping(uint256 => address[]) usersArray;
    mapping(uint256 => mapping(address => Transaction)) receipt;
    uint256 result;
  }
  struct PointTotal {
    uint256 pointAmount;
    uint256 startTime;
    uint256 total;
    mapping(int => uint256) betTotal;
    uint256 homeTeamID;
    uint256 awayTeamID;
    mapping(int => address[]) usersArray;
    mapping(int => mapping(address => Transaction)) receipt;
    int result;
  }

  mapping(address => User) public balances;
  mapping(uint256 => uint256) public totalBetOnGame;
  mapping(uint256 => mapping(uint256 => uint256)) public totalBetOnTeam;
  mapping(uint256 => MoneyLine) public newMoneyLineBet;
  mapping(uint256 => PointSpread) public newPointSpreadBet;
  mapping(uint256 => PointTotal) public newPointTotalBet;

  function returnOdds(
    uint256 gameID,
    uint256 bettingTeamID,
    uint256 opposingTeamID
  ) public view returns (uint256) {
    uint256 bettingTeam = totalBetOnTeam[gameID][bettingTeamID];
    uint256 opposingTeam = totalBetOnTeam[gameID][opposingTeamID];
    if (bettingTeam > 0) {
      uint256 odds = bettingTeam / (bettingTeam + opposingTeam);
      return odds * 100;
    } else {
      return 0;
    }
  }

  function moneyLineBet(
    address user,
    uint256 gameID,
    uint256 teamID,
    uint256 homeTeamID,
    uint256 awayTeamID,
    string memory startTime
  ) public payable {
    require(msg.sender == user, 'You must bet from your own address');
    require(msg.value > 0, 'You must bet something');
    require(
      teamID == homeTeamID || teamID == awayTeamID,
      'You must bet on a team that is playing in this game'
    );
    uint256 tax = (msg.value / 100) * 5;
    uint256 msgValue = (msg.value / 100) * 95;
    MoneyLine storage moneyLine = newMoneyLineBet[gameID];
    User storage userStruct = balances[msg.sender];
    Transaction[] storage receipt = userStruct.receipts;
    Transaction storage transaction = moneyLine.receipt[teamID][msg.sender];
    address[] storage usersArray = moneyLine.usersArray[teamID];
    admin.transfer(tax);
    userStruct.escrow += msgValue;
    receipt.push(
      Transaction(msg.sender, msgValue, teamID, gameID, 'Money Line')
    );
    totalBetOnGame[gameID] += msg.value;
    totalBetOnTeam[gameID][teamID] += msg.value;
    moneyLine.total += msgValue;
    moneyLine.teamTotal[teamID] += msgValue;
    moneyLine.homeTeamID = homeTeamID;
    moneyLine.awayTeamID = awayTeamID;
    moneyLine.startTime = datetimeToUnix(startTime);
    if (moneyLine.receipt[teamID][msg.sender].addr != msg.sender) {
      usersArray.push(msg.sender);
    }
    transaction.addr = msg.sender;
    transaction.amount += msgValue;
    transaction.teamID = teamID;
    transaction.gameID = gameID;
    transaction.betType = 'Money Line';
  }

  function pointSpreadBet(
    address user,
    uint256 gameID,
    uint256 teamID,
    uint256 homeTeamID,
    uint256 awayTeamID,
    string memory startTime,
    int spread
  ) public payable {
    require(msg.sender == user, 'You must bet from your own address');
    require(msg.value > 0, 'You must bet something');
    require(
      teamID == homeTeamID || teamID == awayTeamID,
      'You must bet on a team that is playing in this game'
    );
    uint256 tax = (msg.value / 100) * 5;
    uint256 msgValue = (msg.value / 100) * 95;
    PointSpread storage pointSpread = newPointSpreadBet[gameID];
    User storage userStruct = balances[msg.sender];
    Transaction[] storage receipt = userStruct.receipts;
    Transaction storage transaction = pointSpread.receipt[teamID][msg.sender];
    address[] storage usersArray = pointSpread.usersArray[teamID];
    admin.transfer(tax);
    userStruct.escrow += msgValue;
    receipt.push(
      Transaction(msg.sender, msgValue, teamID, gameID, 'Point Spread')
    );
    totalBetOnGame[gameID] += msg.value;
    totalBetOnTeam[gameID][teamID] += msg.value;
    pointSpread.total += msgValue;
    pointSpread.teamTotal[teamID] += msgValue;
    pointSpread.homeTeamID = homeTeamID;
    pointSpread.awayTeamID = awayTeamID;
    pointSpread.startTime = datetimeToUnix(startTime);
    pointSpread.spreadAmount[teamID] = spread;
    if (pointSpread.receipt[teamID][msg.sender].addr != msg.sender) {
      usersArray.push(msg.sender);
    }
    transaction.addr = msg.sender;
    transaction.amount += msgValue;
    transaction.teamID = teamID;
    transaction.gameID = gameID;
    transaction.betType = 'Point Spread';
  }

  function pointTotalBet(
    address user,
    uint256 gameID,
    uint256 pointAmount,
    uint256 homeTeamID,
    uint256 awayTeamID,
    string memory startTime,
    int value
  ) public payable {
    require(msg.sender == user, 'You must bet from your own address');
    require(msg.value > 0, 'You must bet something');
    uint256 tax = (msg.value / 100) * 5;
    uint256 msgValue = (msg.value / 100) * 95;
    PointTotal storage pointTotal = newPointTotalBet[gameID];
    User storage userStruct = balances[msg.sender];
    Transaction[] storage receipt = userStruct.receipts;
    Transaction storage transaction = pointTotal.receipt[value][msg.sender];
    address[] storage usersArray = pointTotal.usersArray[value];
    admin.transfer(tax);
    userStruct.escrow += msgValue;
    receipt.push(Transaction(msg.sender, msgValue, 0, gameID, 'Point Total'));
    totalBetOnGame[gameID] += msg.value;
    pointTotal.total += msgValue;
    pointTotal.betTotal[value] += msgValue;
    pointTotal.homeTeamID = homeTeamID;
    pointTotal.awayTeamID = awayTeamID;
    pointTotal.startTime = datetimeToUnix(startTime);
    pointTotal.pointAmount = pointAmount;
    if (pointTotal.receipt[value][msg.sender].addr != msg.sender) {
      usersArray.push(msg.sender);
    }
    transaction.addr = msg.sender;
    transaction.amount += msgValue;
    transaction.teamID = 0;
    transaction.gameID = gameID;
    transaction.betType = 'Point Total';
  }

  function returnMoneyLineBetReceipt(
    uint256 gameID,
    uint256 teamID
  ) public view returns (Transaction memory) {
    return newMoneyLineBet[gameID].receipt[teamID][msg.sender];
  }

  function returnPointSpreadBetReceipt(
    uint256 gameID,
    uint256 teamID
  ) public view returns (Transaction memory) {
    return newPointSpreadBet[gameID].receipt[teamID][msg.sender];
  }

  function returnPointTotalBetReceipt(
    uint256 gameID,
    int value
  ) public view returns (Transaction memory) {
    return newPointTotalBet[gameID].receipt[value][msg.sender];
  }

  function returnMoneyLineUsersArray(
    uint256 gameID,
    uint256 teamID
  ) public view returns (address[] memory) {
    return newMoneyLineBet[gameID].usersArray[teamID];
  }

  function returnPointSpreadUsersArray(
    uint256 gameID,
    uint256 teamID
  ) public view returns (address[] memory) {
    return newPointSpreadBet[gameID].usersArray[teamID];
  }

  function returnPointTotalUsersArray(
    uint256 gameID,
    int value
  ) public view returns (address[] memory) {
    return newPointTotalBet[gameID].usersArray[value];
  }

  function returnPointSpreadGameAmount(
    uint256 gameID,
    uint256 teamID
  ) public view returns (int) {
    return newPointSpreadBet[gameID].spreadAmount[teamID];
  }

  function returnPointTotalGameAmount(
    uint256 gameID
  ) public view returns (uint256) {
    return newPointTotalBet[gameID].pointAmount;
  }

  function returnEscrow() public view returns (uint256) {
    return balances[msg.sender].escrow;
  }

  function returnReceipts() public view returns (Transaction[] memory) {
    return balances[msg.sender].receipts;
  }

  function datetimeToUnix(
    string memory datetimeString
  ) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(datetimeString)));
  }

  function transferEther() external {
    require(msg.sender == admin, 'You are not the admin');
    admin.transfer(address(this).balance);
  }
}
