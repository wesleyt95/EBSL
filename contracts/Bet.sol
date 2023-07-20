// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {AutomateTaskCreator} from './AutomateTaskCreator.sol';
import {Module, ModuleData} from './Types.sol';

contract Bet is AutomateTaskCreator {
  address payable admin;

  constructor()
    AutomateTaskCreator(
      0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0,
      address(this)
    )
  {
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
    uint256 time;
    bool active;
  }
  struct MoneyLine {
    uint256 startTime;
    uint256 total;
    mapping(uint256 => uint256) teamTotal;
    uint256 homeTeamID;
    uint256 awayTeamID;
    mapping(uint256 => address payable[]) usersArray;
    mapping(uint256 => mapping(address => Transaction)) receipt;
    bytes32 taskID;
  }
  struct PointSpread {
    mapping(address => mapping(uint256 => int)) spreadAmount;
    uint256 startTime;
    uint256 total;
    mapping(uint256 => uint256) teamTotal;
    uint256 homeTeamID;
    uint256 awayTeamID;
    mapping(uint256 => address payable[]) usersArray;
    mapping(uint256 => mapping(address => Transaction)) receipt;
    bytes32 taskID;
  }
  struct PointTotal {
    mapping(address => uint256) pointAmount;
    uint256 startTime;
    uint256 total;
    uint256 homeTeamID;
    uint256 awayTeamID;
    address payable[] usersArray;
    mapping(address => Transaction) receipt;
    bytes32 taskID;
  }

  mapping(address => User) public userReceipts;
  mapping(uint256 => uint256) public totalBetOnGame;
  mapping(uint256 => mapping(uint256 => uint256)) public totalBetOnTeam;
  mapping(uint256 => MoneyLine) public newMoneyLineBet;
  mapping(uint256 => PointSpread) public newPointSpreadBet;
  mapping(uint256 => PointTotal) public newPointTotalBet;
  mapping(uint256 => uint256) public visitor_team_score;
  mapping(uint256 => uint256) public home_team_score;

  function returnOdds(
    uint256 gameID,
    uint256 bettingTeamID
  ) public view returns (uint256) {
    uint256 bettingTeam = totalBetOnTeam[gameID][bettingTeamID];
    uint256 gameTotal = totalBetOnGame[gameID];
    uint256 odds = (bettingTeam * 100) / gameTotal;
    return odds;
  }

  function _getWeb3FunctionArgsHex(
    address web3fAddress,
    uint256 gameID,
    uint256 startTime
  ) internal pure returns (bytes memory web3FunctionArgsHex) {
    web3FunctionArgsHex = abi.encode(web3fAddress, gameID, startTime);
  }

  function moneyLineBet(
    address user,
    uint256 gameID,
    uint256 teamID,
    uint256 homeTeamID,
    uint256 awayTeamID,
    uint256 startTime,
    string memory web3ContractAddress
  ) public payable {
    require(homeTeamID != awayTeamID);
    require(msg.sender == user, 'You must bet from your own address');
    require(msg.value > 0, 'You must bet something');
    require(
      teamID == homeTeamID || teamID == awayTeamID,
      'You must bet on a team that is playing in this game'
    );
    if (newMoneyLineBet[gameID].taskID == bytes32('')) {
      ModuleData memory moduleData = ModuleData({
        modules: new Module[](2),
        args: new bytes[](2)
      });

      moduleData.modules[0] = Module.PROXY;
      moduleData.modules[1] = Module.WEB3_FUNCTION;

      moduleData.args[0] = _proxyModuleArg();
      moduleData.args[1] = _web3FunctionModuleArg(
        web3ContractAddress,
        _getWeb3FunctionArgsHex(address(this), gameID, startTime)
      );

      newMoneyLineBet[gameID].taskID = _createTask(
        address(this),
        abi.encode(this.rewardMoneyLineWinners.selector),
        moduleData,
        address(0)
      );
    }
    uint256 tax = (msg.value * 5) / 100;
    uint256 msgValue = (msg.value * 95) / 100;
    MoneyLine storage moneyLine = newMoneyLineBet[gameID];
    Transaction[] storage receipt = userReceipts[msg.sender].receipts;
    Transaction storage transaction = moneyLine.receipt[teamID][msg.sender];
    address payable[] storage usersArray = moneyLine.usersArray[teamID];
    admin.transfer(tax);
    userReceipts[msg.sender].escrow += msgValue;
    receipt.push(
      Transaction(
        msg.sender,
        msgValue,
        teamID,
        gameID,
        'Money Line',
        block.timestamp,
        true
      )
    );
    totalBetOnGame[gameID] += msg.value;
    totalBetOnTeam[gameID][teamID] += msg.value;
    moneyLine.total += msgValue;
    moneyLine.teamTotal[teamID] += msgValue;
    moneyLine.homeTeamID = homeTeamID;
    moneyLine.awayTeamID = awayTeamID;
    moneyLine.startTime = startTime;
    if (
      newMoneyLineBet[gameID].receipt[teamID][msg.sender].addr != msg.sender
    ) {
      usersArray.push(payable(msg.sender));
    }
    transaction.addr = msg.sender;
    transaction.amount += msgValue;
    transaction.teamID = teamID;
    transaction.gameID = gameID;
    transaction.betType = 'Money Line';
    transaction.time = block.timestamp;
    transaction.active = true;
  }

  function pointSpreadBet(
    address user,
    uint256 gameID,
    uint256 teamID,
    uint256 homeTeamID,
    uint256 awayTeamID,
    uint256 startTime,
    int spread,
    string memory web3ContractAddress
  ) public payable {
    require(
      newPointSpreadBet[gameID].receipt[teamID][msg.sender].addr != msg.sender,
      'You are only allowed to place multiple Money Line bets on the same game'
    );
    require(homeTeamID != awayTeamID);
    require(msg.sender == user, 'You must bet from your own address');
    require(msg.value > 0, 'You must bet something');
    require(
      teamID == homeTeamID || teamID == awayTeamID,
      'You must bet on a team that is playing in this game'
    );
    if (newPointSpreadBet[gameID].taskID == bytes32('')) {
      ModuleData memory moduleData = ModuleData({
        modules: new Module[](2),
        args: new bytes[](2)
      });

      moduleData.modules[0] = Module.PROXY;
      moduleData.modules[1] = Module.WEB3_FUNCTION;

      moduleData.args[0] = _proxyModuleArg();
      moduleData.args[1] = _web3FunctionModuleArg(
        web3ContractAddress,
        _getWeb3FunctionArgsHex(address(this), gameID, startTime)
      );

      newPointSpreadBet[gameID].taskID = _createTask(
        address(this),
        abi.encode(this.rewardPointSpreadWinners.selector),
        moduleData,
        address(0)
      );
    }
    uint256 tax = (msg.value * 5) / 100;
    uint256 msgValue = (msg.value * 95) / 100;
    PointSpread storage pointSpread = newPointSpreadBet[gameID];
    Transaction[] storage receipt = userReceipts[msg.sender].receipts;
    Transaction storage transaction = pointSpread.receipt[teamID][msg.sender];
    address payable[] storage usersArray = pointSpread.usersArray[teamID];
    admin.transfer(tax);
    userReceipts[msg.sender].escrow += msgValue;
    receipt.push(
      Transaction(
        msg.sender,
        msgValue,
        teamID,
        gameID,
        'Point Spread',
        block.timestamp,
        true
      )
    );
    totalBetOnGame[gameID] += msg.value;
    totalBetOnTeam[gameID][teamID] += msg.value;
    pointSpread.total += msgValue;
    pointSpread.teamTotal[teamID] += msgValue;
    pointSpread.homeTeamID = homeTeamID;
    pointSpread.awayTeamID = awayTeamID;
    pointSpread.startTime = startTime;
    pointSpread.spreadAmount[msg.sender][teamID] = spread;

    usersArray.push(payable(msg.sender));

    transaction.addr = msg.sender;
    transaction.amount += msgValue;
    transaction.teamID = teamID;
    transaction.gameID = gameID;
    transaction.betType = 'Point Spread';
    transaction.time = block.timestamp;
    transaction.active = true;
  }

  function pointTotalBet(
    address user,
    uint256 gameID,
    uint256 pointAmount,
    uint256 homeTeamID,
    uint256 awayTeamID,
    uint256 startTime,
    string memory web3ContractAddress
  ) public payable {
    require(
      newPointTotalBet[gameID].receipt[msg.sender].addr != msg.sender,
      'You are only allowed to place multiple Money Line bets on the same game'
    );
    require(homeTeamID != awayTeamID);
    require(msg.sender == user, 'You must bet from your own address');
    require(msg.value > 0, 'You must bet something');
    if (newPointTotalBet[gameID].taskID == bytes32('')) {
      ModuleData memory moduleData = ModuleData({
        modules: new Module[](2),
        args: new bytes[](2)
      });

      moduleData.modules[0] = Module.PROXY;
      moduleData.modules[1] = Module.WEB3_FUNCTION;

      moduleData.args[0] = _proxyModuleArg();
      moduleData.args[1] = _web3FunctionModuleArg(
        web3ContractAddress,
        _getWeb3FunctionArgsHex(address(this), gameID, startTime)
      );

      newPointTotalBet[gameID].taskID = _createTask(
        address(this),
        abi.encode(this.rewardPointTotalWinners.selector),
        moduleData,
        address(0)
      );
    }
    uint256 tax = (msg.value * 5) / 100;
    uint256 msgValue = (msg.value * 95) / 100;
    PointTotal storage pointTotal = newPointTotalBet[gameID];
    Transaction[] storage receipt = userReceipts[msg.sender].receipts;
    Transaction storage transaction = pointTotal.receipt[msg.sender];
    address payable[] storage usersArray = pointTotal.usersArray;
    admin.transfer(tax);
    userReceipts[msg.sender].escrow += msgValue;
    receipt.push(
      Transaction(
        msg.sender,
        msgValue,
        0,
        gameID,
        'Point Total',
        block.timestamp,
        true
      )
    );

    totalBetOnGame[gameID] += msg.value;
    totalBetOnTeam[gameID][homeTeamID] += msg.value;
    totalBetOnTeam[gameID][awayTeamID] += msg.value;
    pointTotal.total += msgValue;
    pointTotal.homeTeamID = homeTeamID;
    pointTotal.awayTeamID = awayTeamID;
    pointTotal.startTime = startTime;
    pointTotal.pointAmount[msg.sender] = pointAmount;

    usersArray.push(payable(msg.sender));

    transaction.addr = msg.sender;
    transaction.amount += msgValue;
    transaction.teamID = 0;
    transaction.gameID = gameID;
    transaction.betType = 'Point Total';
    transaction.time = block.timestamp;
    transaction.active = true;
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
    uint256 gameID
  ) public view returns (Transaction memory) {
    return newPointTotalBet[gameID].receipt[msg.sender];
  }

  function returnMoneyLineBetTotal(
    uint256 gameID,
    uint256 teamID
  ) public view returns (uint256) {
    return newMoneyLineBet[gameID].teamTotal[teamID];
  }

  function returnPointSpreadBetTotal(
    uint256 gameID,
    uint256 teamID
  ) public view returns (uint256) {
    return newPointSpreadBet[gameID].teamTotal[teamID];
  }

  function returnPointTotalBetTotal(
    uint256 gameID
  ) public view returns (uint256) {
    return newPointTotalBet[gameID].total;
  }

  function returnEscrow() public view returns (uint256) {
    return userReceipts[msg.sender].escrow;
  }

  function returnReceipts() public view returns (Transaction[] memory) {
    return userReceipts[msg.sender].receipts;
  }

  function rewardMoneyLineWinners(
    uint256 gameID,
    uint256 winnerID,
    uint256 loserID
  ) public onlyDedicatedMsgSender {
    for (
      uint i = 0;
      i < newMoneyLineBet[gameID].usersArray[winnerID].length;
      i++
    ) {
      address payable winningUserID = newMoneyLineBet[gameID].usersArray[
        winnerID
      ][i];
      uint256 msgValue = newMoneyLineBet[gameID]
      .receipt[winnerID][winningUserID].amount;
      uint256 stake = msgValue / newMoneyLineBet[gameID].teamTotal[winnerID];
      winningUserID.transfer(newMoneyLineBet[gameID].total * stake);
      userReceipts[winningUserID].escrow -= msgValue;
      for (uint x = 0; x < userReceipts[winningUserID].receipts.length; x++) {
        Transaction memory myArray = userReceipts[winningUserID].receipts[x];
        if (
          myArray.gameID == gameID &&
          keccak256(abi.encodePacked(myArray.betType)) ==
          keccak256(abi.encodePacked('Money Line'))
        ) {
          myArray.active = false;
        }
      }
    }
    for (
      uint i = 0;
      i < newMoneyLineBet[gameID].usersArray[loserID].length;
      i++
    ) {
      address payable losingUserID = newMoneyLineBet[gameID].usersArray[
        loserID
      ][i];
      uint256 msgValue = newMoneyLineBet[gameID]
      .receipt[loserID][losingUserID].amount;
      userReceipts[losingUserID].escrow -= msgValue;
      for (uint x = 0; x < userReceipts[losingUserID].receipts.length; x++) {
        Transaction memory myArray = userReceipts[losingUserID].receipts[x];
        if (
          myArray.gameID == gameID &&
          keccak256(abi.encodePacked(myArray.betType)) ==
          keccak256(abi.encodePacked('Money Line'))
        ) {
          myArray.active = false;
        }
      }
    }
  }

  function rewardPointSpreadWinners(
    uint256 gameID,
    uint256 winnerID,
    uint256 loserID,
    int winnerScore,
    int loserScore
  ) public onlyDedicatedMsgSender {
    for (
      uint i = 0;
      i < newPointSpreadBet[gameID].usersArray[winnerID].length;
      i++
    ) {
      address payable winningUserID = newPointSpreadBet[gameID].usersArray[
        winnerID
      ][i];
      uint256 msgValue = newPointSpreadBet[gameID]
      .receipt[winnerID][winningUserID].amount;
      int spread = newPointSpreadBet[gameID].spreadAmount[msg.sender][winnerID];
      if (winnerScore + spread > loserScore) {
        winningUserID.transfer(
          (msgValue / newPointSpreadBet[gameID].total) * msgValue
        );
      }

      userReceipts[winningUserID].escrow -= msgValue;
      for (uint x = 0; x < userReceipts[winningUserID].receipts.length; x++) {
        Transaction memory myArray = userReceipts[winningUserID].receipts[x];
        if (
          keccak256(abi.encodePacked(myArray.gameID)) ==
          keccak256(abi.encodePacked(gameID)) &&
          keccak256(abi.encodePacked(myArray.betType)) ==
          keccak256(abi.encodePacked('Point Spread'))
        ) {
          myArray.active = false;
        }
      }
    }
    for (
      uint i = 0;
      i < newPointSpreadBet[gameID].usersArray[loserID].length;
      i++
    ) {
      address payable losingUserID = newPointSpreadBet[gameID].usersArray[
        loserID
      ][i];
      uint256 msgValue = newPointSpreadBet[gameID]
      .receipt[loserID][losingUserID].amount;
      userReceipts[losingUserID].escrow -= msgValue;
      int spread = newPointSpreadBet[gameID].spreadAmount[msg.sender][loserID];
      if (loserScore + spread > winnerScore) {
        losingUserID.transfer(
          (msgValue / newPointSpreadBet[gameID].total) * msgValue
        );
      }
      for (uint x = 0; x < userReceipts[losingUserID].receipts.length; x++) {
        Transaction memory myArray = userReceipts[losingUserID].receipts[x];
        if (
          keccak256(abi.encodePacked(myArray.gameID)) ==
          keccak256(abi.encodePacked(gameID)) &&
          keccak256(abi.encodePacked(myArray.betType)) ==
          keccak256(abi.encodePacked('Point Spread'))
        ) {
          myArray.active = false;
        }
      }
    }
  }

  function rewardPointTotalWinners(
    uint256 gameID,
    uint256 total
  ) public onlyDedicatedMsgSender {
    for (uint i = 0; i < newPointTotalBet[gameID].usersArray.length; i++) {
      address payable winningUserID = newPointTotalBet[gameID].usersArray[i];
      uint256 msgValue = newPointTotalBet[gameID].receipt[winningUserID].amount;
      if (total > newPointTotalBet[gameID].pointAmount[winningUserID]) {
        winningUserID.transfer(
          (msgValue / newPointTotalBet[gameID].total) * msgValue
        );
      } else if (total == newPointTotalBet[gameID].pointAmount[winningUserID]) {
        winningUserID.transfer(msgValue);
      }

      userReceipts[winningUserID].escrow -= msgValue;
      for (uint x = 0; x < userReceipts[winningUserID].receipts.length; x++) {
        Transaction memory myArray = userReceipts[winningUserID].receipts[x];
        if (
          myArray.gameID == gameID &&
          (keccak256(abi.encodePacked(myArray.betType))) ==
          (keccak256(abi.encodePacked('Point Total')))
        ) {
          myArray.active = false;
        }
      }
    }
  }
}
