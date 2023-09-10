// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {AutomateTaskCreator} from './AutomateTaskCreator.sol';
import {Module, ModuleData} from './Types.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract Bet is AutomateTaskCreator {
  address payable private admin;
  string private moneyLineFunctionHash;
  string private pointSpreadFunctionHash;
  string private pointTotalFunctionHash;

  constructor(
    string memory _moneyLineFunctionHash,
    string memory _pointSpreadFunctionHash,
    string memory _pointTotalFunctionHash
  )
    AutomateTaskCreator(
      0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0,
      address(this)
    )
  {
    admin = payable(msg.sender);
    moneyLineFunctionHash = _moneyLineFunctionHash;
    pointSpreadFunctionHash = _pointSpreadFunctionHash;
    pointTotalFunctionHash = _pointTotalFunctionHash;
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
    uint256 total;
    mapping(uint256 => uint256) teamTotal;
    uint256 homeTeamID;
    uint256 awayTeamID;
    mapping(uint256 => address payable[]) usersArray;
    mapping(uint256 => mapping(address => Transaction)) receipt;
    bytes32 taskID;
  }
  struct PointSpread {
    mapping(address => int) spreadAmount;
    uint256 total;
    mapping(uint256 => uint256) teamTotal;
    uint256 homeTeamID;
    uint256 awayTeamID;
    address payable[] usersArray;
    mapping(address => Transaction) receipt;
    bytes32 taskID;
    address payable[] winners;
  }
  struct PointTotal {
    mapping(address => uint256) pointAmount;
    uint256 total;
    uint256 homeTeamID;
    uint256 awayTeamID;
    address payable[] usersArray;
    mapping(address => Transaction) receipt;
    bytes32 taskID;
    address payable[] winners;
  }
  address[] public blockedUsers;
  mapping(address => User) public userReceipts;
  mapping(uint256 => uint256) public totalBetOnGame;
  mapping(uint256 => mapping(uint256 => uint256)) public totalBetOnTeam;
  mapping(uint256 => MoneyLine) public newMoneyLineBet;
  mapping(uint256 => PointSpread) public newPointSpreadBet;
  mapping(uint256 => PointTotal) public newPointTotalBet;

  function checkSender(address user) public view returns (bool) {
    for (uint i = 0; i < blockedUsers.length; i++) {
      if (blockedUsers[i] == user) {
        return true;
      }
    }
    return false;
  }

  function returnOdds(
    uint256 gameID,
    uint256 bettingTeamID
  ) public view returns (uint256 odds) {
    uint256 bettingTeam = totalBetOnTeam[gameID][bettingTeamID];
    uint256 gameTotal = totalBetOnGame[gameID];
    odds = (bettingTeam * 100) / gameTotal;
  }

  function moneyLineBet(
    uint256 gameID,
    uint256 teamID,
    uint256 homeTeamID,
    uint256 awayTeamID,
    uint256 startTime
  ) public payable {
    require(msg.sender == tx.origin);
    require(0 < startTime);
    require(!checkSender(msg.sender));
    require(msg.value > 0);
    MoneyLine storage moneyLine = newMoneyLineBet[gameID];
    if (newMoneyLineBet[gameID].taskID == bytes32('')) {
      ModuleData memory moduleData = ModuleData({
        modules: new Module[](2),
        args: new bytes[](2)
      });
      moduleData.modules[0] = Module.PROXY;
      moduleData.modules[1] = Module.WEB3_FUNCTION;
      moduleData.args[0] = _proxyModuleArg();
      moduleData.args[1] = _web3FunctionModuleArg(
        moneyLineFunctionHash,
        abi.encode(Strings.toHexString(address(this)), gameID)
      );

      moneyLine.taskID = _createTask(
        address(this),
        abi.encode(this.rewardMoneyLineWinners.selector),
        moduleData,
        address(0)
      );
    }
    uint256 tax = (msg.value * 5) / 100;

    Transaction[] storage receipt = userReceipts[msg.sender].receipts;
    Transaction storage transaction = moneyLine.receipt[teamID][msg.sender];
    address payable[] storage usersArray = moneyLine.usersArray[teamID];
    admin.transfer(tax);
    userReceipts[msg.sender].escrow += msg.value - tax;
    receipt.push(
      Transaction(
        msg.sender,
        msg.value - tax,
        teamID,
        gameID,
        'Money Line',
        block.timestamp,
        true
      )
    );
    totalBetOnGame[gameID] += msg.value;
    totalBetOnTeam[gameID][teamID] += msg.value;
    moneyLine.total += msg.value - tax;
    moneyLine.teamTotal[teamID] += msg.value - tax;
    moneyLine.homeTeamID = homeTeamID;
    moneyLine.awayTeamID = awayTeamID;
    if (
      newMoneyLineBet[gameID].receipt[teamID][msg.sender].addr != msg.sender
    ) {
      usersArray.push(payable(msg.sender));
    }
    transaction.addr = msg.sender;
    transaction.amount += msg.value - tax;
    transaction.teamID = teamID;
    transaction.gameID = gameID;
    transaction.betType = 'Money Line';
    transaction.time = block.timestamp;
    transaction.active = true;
  }

  function pointSpreadBet(
    uint256 gameID,
    uint256 teamID,
    uint256 homeTeamID,
    uint256 awayTeamID,
    int spread,
    uint256 startTime
  ) public payable {
    require(msg.sender == tx.origin);
    require(block.timestamp < startTime);
    require(!checkSender(msg.sender));
    require(newPointSpreadBet[gameID].receipt[msg.sender].addr != msg.sender);
    require(msg.value > 0);
    PointSpread storage pointSpread = newPointSpreadBet[gameID];
    if (newPointSpreadBet[gameID].taskID == bytes32('')) {
      ModuleData memory moduleData = ModuleData({
        modules: new Module[](2),
        args: new bytes[](2)
      });
      moduleData.modules[0] = Module.PROXY;
      moduleData.modules[1] = Module.WEB3_FUNCTION;
      moduleData.args[0] = _proxyModuleArg();
      moduleData.args[1] = _web3FunctionModuleArg(
        pointSpreadFunctionHash,
        abi.encode(Strings.toHexString(address(this)), gameID)
      );
      pointSpread.taskID = _createTask(
        address(this),
        abi.encode(this.rewardPointSpreadWinners.selector),
        moduleData,
        address(0)
      );
    }
    uint256 tax = (msg.value * 5) / 100;

    Transaction[] storage receipt = userReceipts[msg.sender].receipts;
    Transaction storage transaction = pointSpread.receipt[msg.sender];
    address payable[] storage usersArray = pointSpread.usersArray;
    admin.transfer(tax);
    userReceipts[msg.sender].escrow += msg.value - tax;
    receipt.push(
      Transaction(
        msg.sender,
        msg.value - tax,
        teamID,
        gameID,
        'Point Spread',
        block.timestamp,
        true
      )
    );
    totalBetOnGame[gameID] += msg.value;
    totalBetOnTeam[gameID][teamID] += msg.value;
    pointSpread.total += msg.value - tax;
    pointSpread.teamTotal[teamID] += msg.value - tax;
    pointSpread.homeTeamID = homeTeamID;
    pointSpread.awayTeamID = awayTeamID;
    pointSpread.spreadAmount[msg.sender] = spread;
    usersArray.push(payable(msg.sender));
    transaction.addr = msg.sender;
    transaction.amount += msg.value - tax;
    transaction.teamID = teamID;
    transaction.gameID = gameID;
    transaction.betType = 'Point Spread';
    transaction.time = block.timestamp;
    transaction.active = true;
  }

  function pointTotalBet(
    uint256 gameID,
    uint256 overUnder,
    uint256 homeTeamID,
    uint256 awayTeamID,
    uint256 pointAmount,
    uint256 startTime
  ) public payable {
    require(msg.sender == tx.origin);
    require(block.timestamp < startTime);
    require(!checkSender(msg.sender));
    require(newPointTotalBet[gameID].receipt[msg.sender].addr != msg.sender);
    require(msg.value > 0);
    PointTotal storage pointTotal = newPointTotalBet[gameID];
    if (newPointTotalBet[gameID].taskID == bytes32('')) {
      ModuleData memory moduleData = ModuleData({
        modules: new Module[](2),
        args: new bytes[](2)
      });
      moduleData.modules[0] = Module.PROXY;
      moduleData.modules[1] = Module.WEB3_FUNCTION;
      moduleData.args[0] = _proxyModuleArg();
      moduleData.args[1] = _web3FunctionModuleArg(
        pointTotalFunctionHash,
        abi.encode(Strings.toHexString(address(this)), gameID)
      );
      pointTotal.taskID = _createTask(
        address(this),
        abi.encode(this.rewardPointTotalWinners.selector),
        moduleData,
        address(0)
      );
    }
    uint256 tax = (msg.value * 5) / 100;

    Transaction[] storage receipt = userReceipts[msg.sender].receipts;
    Transaction storage transaction = pointTotal.receipt[msg.sender];
    address payable[] storage usersArray = pointTotal.usersArray;
    admin.transfer(tax);
    userReceipts[msg.sender].escrow += msg.value - tax;
    receipt.push(
      Transaction(
        msg.sender,
        msg.value - tax,
        overUnder,
        gameID,
        'Point Total',
        block.timestamp,
        true
      )
    );
    totalBetOnGame[gameID] += msg.value;
    totalBetOnTeam[gameID][homeTeamID] += msg.value / 2;
    totalBetOnTeam[gameID][awayTeamID] += msg.value / 2;
    pointTotal.total += msg.value - tax;
    pointTotal.homeTeamID = homeTeamID;
    pointTotal.awayTeamID = awayTeamID;
    pointTotal.pointAmount[msg.sender] = pointAmount;
    usersArray.push(payable(msg.sender));
    transaction.addr = msg.sender;
    transaction.amount += msg.value - tax;
    transaction.teamID = overUnder;
    transaction.gameID = gameID;
    transaction.betType = 'Point Total';
    transaction.time = block.timestamp;
    transaction.active = true;
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
      uint256 stake = (msgValue * 100) /
        newMoneyLineBet[gameID].teamTotal[winnerID];
      if (!checkSender(winningUserID)) {
        winningUserID.transfer((newMoneyLineBet[gameID].total * stake) / 100);
      }
      userReceipts[winningUserID].escrow -= msgValue;
      for (uint x = 0; x < userReceipts[winningUserID].receipts.length; x++) {
        Transaction storage myArray = userReceipts[winningUserID].receipts[x];
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
        Transaction storage myArray = userReceipts[losingUserID].receipts[x];
        if (
          myArray.gameID == gameID &&
          keccak256(abi.encodePacked(myArray.betType)) ==
          keccak256(abi.encodePacked('Money Line'))
        ) {
          myArray.active = false;
        }
      }
    }
    _cancelTask(newMoneyLineBet[gameID].taskID);
  }

  function rewardPointSpreadWinners(
    uint256 gameID,
    int homeScore,
    int awayScore,
    uint256 homeTeamID,
    uint256 awayTeamID
  ) public onlyDedicatedMsgSender {
    address payable[] storage winners = newPointSpreadBet[gameID].winners;
    uint winnersPurse = 0;
    for (uint i = 0; i < newPointSpreadBet[gameID].usersArray.length; i++) {
      address payable currentUserID = newPointSpreadBet[gameID].usersArray[i];
      uint256 msgValue = newPointSpreadBet[gameID]
        .receipt[currentUserID]
        .amount;
      int spread = newPointSpreadBet[gameID].spreadAmount[currentUserID];
      if (
        newPointSpreadBet[gameID].receipt[currentUserID].teamID == homeTeamID &&
        (homeScore * 10) + spread > awayScore * 10 &&
        !checkSender(currentUserID)
      ) {
        winners.push(currentUserID);
        winnersPurse += msgValue;
      } else if (
        newPointSpreadBet[gameID].receipt[currentUserID].teamID == awayTeamID &&
        (awayScore * 10) + spread > homeScore * 10 &&
        !checkSender(currentUserID)
      ) {
        winners.push(currentUserID);
        winnersPurse += msgValue;
      }
      userReceipts[currentUserID].escrow -= msgValue;
      for (uint x = 0; x < userReceipts[currentUserID].receipts.length; x++) {
        Transaction storage myArray = userReceipts[currentUserID].receipts[x];
        if (
          myArray.gameID == gameID &&
          keccak256(abi.encodePacked(myArray.betType)) ==
          keccak256(abi.encodePacked('Point Spread'))
        ) {
          myArray.active = false;
        }
      }
    }
    for (uint b = 0; b < winners.length; b++) {
      uint256 msgValue = newPointSpreadBet[gameID].receipt[winners[b]].amount;
      uint256 share = (msgValue * 100) / winnersPurse;
      winners[b].transfer((newPointSpreadBet[gameID].total * share) / 100);
    }
    _cancelTask(newPointSpreadBet[gameID].taskID);
  }

  function rewardPointTotalWinners(
    uint256 gameID,
    uint256 total
  ) public onlyDedicatedMsgSender {
    address payable[] storage winners = newPointTotalBet[gameID].winners;
    uint winnersPurse = 0;
    for (uint i = 0; i < newPointTotalBet[gameID].usersArray.length; i++) {
      address payable currentUserID = newPointTotalBet[gameID].usersArray[i];
      uint256 msgValue = newPointTotalBet[gameID].receipt[currentUserID].amount;
      if (
        newPointTotalBet[gameID].receipt[currentUserID].teamID == 99 &&
        total * 10 < newPointTotalBet[gameID].pointAmount[currentUserID] &&
        !checkSender(currentUserID)
      ) {
        winners.push(currentUserID);
        winnersPurse += msgValue;
      } else if (
        newPointTotalBet[gameID].receipt[currentUserID].teamID == 100 &&
        total * 10 > newPointTotalBet[gameID].pointAmount[currentUserID] &&
        !checkSender(currentUserID)
      ) {
        winners.push(currentUserID);
        winnersPurse += msgValue;
      }
      userReceipts[currentUserID].escrow -= msgValue;

      for (uint x = 0; x < userReceipts[currentUserID].receipts.length; x++) {
        Transaction storage myArray = userReceipts[currentUserID].receipts[x];
        if (
          myArray.gameID == gameID &&
          (keccak256(abi.encodePacked(myArray.betType))) ==
          (keccak256(abi.encodePacked('Point Total')))
        ) {
          myArray.active = false;
        }
      }
    }
    for (uint b = 0; b < winners.length; b++) {
      uint256 msgValue = newPointTotalBet[gameID].receipt[winners[b]].amount;
      uint256 share = (msgValue * 100) / winnersPurse;
      winners[b].transfer((newPointTotalBet[gameID].total * share) / 100);
    }
    _cancelTask(newPointTotalBet[gameID].taskID);
  }

  function returnMoneyLineBetReceipt(
    uint256 gameID,
    uint256 teamID
  ) public view returns (Transaction memory data) {
    data = newMoneyLineBet[gameID].receipt[teamID][msg.sender];
  }

  function returnPointSpreadBetReceipt(
    uint256 gameID
  ) public view returns (Transaction memory data) {
    data = newPointSpreadBet[gameID].receipt[msg.sender];
  }

  function returnPointTotalBetReceipt(
    uint256 gameID
  ) public view returns (Transaction memory data) {
    data = newPointTotalBet[gameID].receipt[msg.sender];
  }

  function returnReceipts() public view returns (Transaction[] memory data) {
    data = userReceipts[msg.sender].receipts;
  }

  function returnEscrow() public view returns (uint256 data) {
    data = userReceipts[msg.sender].escrow;
  }

  function returnMoneyLineBetTotal(
    uint256 gameID,
    uint256 teamID
  ) public view returns (uint256 data) {
    data = newMoneyLineBet[gameID].teamTotal[teamID];
  }

  function returnPointSpreadBetTotal(
    uint256 gameID,
    uint256 teamID
  ) public view returns (uint256 data) {
    data = newPointSpreadBet[gameID].teamTotal[teamID];
  }

  function returnPointTotalBetTotal(
    uint256 gameID
  ) public view returns (uint256 data) {
    data = newPointTotalBet[gameID].total;
  }

  function blockUser(address user) public {
    require(msg.sender == admin);
    blockedUsers.push(user);
  }

  function deposit(
    uint256 _amount,
    address _token,
    address _sponsor
  ) public payable {
    _depositFunds1Balance(_amount, _token, _sponsor);
  }
}
