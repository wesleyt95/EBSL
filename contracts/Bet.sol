// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {AutomateTaskCreator} from './AutomateTaskCreator.sol';
import {Module, ModuleData} from './Types.sol';

contract Bet is AutomateTaskCreator {
  address payable private admin;
  string private moneyLineFunctionHash;
  string private pointSpreadFunctionHash;
  string private pointTotalFunctionHash;

  constructor(
    string memory _moneyLineFunctionHash,
    string memory _pointTotalFunctionHash,
    string memory _pointSpreadFunctionHash
  )
    AutomateTaskCreator(
      0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0,
      address(this)
    )
  {
    admin = payable(msg.sender);
    moneyLineFunctionHash = _moneyLineFunctionHash;
    pointTotalFunctionHash = _pointTotalFunctionHash;
    pointSpreadFunctionHash = _pointSpreadFunctionHash;
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
  }
  struct PointTotal {
    mapping(address => uint256) pointAmount;
    uint256 total;
    uint256 homeTeamID;
    uint256 awayTeamID;
    address payable[] usersArray;
    mapping(address => Transaction) receipt;
    bytes32 taskID;
  }
  address[] public blockedUsers;
  mapping(address => User) public userReceipts;
  mapping(uint256 => uint256) public totalBetOnGame;
  mapping(uint256 => mapping(uint256 => uint256)) public totalBetOnTeam;
  mapping(uint256 => MoneyLine) public newMoneyLineBet;
  mapping(uint256 => PointSpread) public newPointSpreadBet;
  mapping(uint256 => PointTotal) public newPointTotalBet;
  mapping(uint256 => uint256) public visitor_team_score;
  mapping(uint256 => uint256) public home_team_score;

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

  function _returnWeb3FunctionArgsHex(
    address web3fAddress,
    uint256 gameID,
    uint256 startTime
  ) internal pure returns (bytes memory web3FunctionArgsHex) {
    web3FunctionArgsHex = abi.encode(web3fAddress, gameID, startTime);
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
        _returnWeb3FunctionArgsHex(address(this), gameID, startTime)
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
    require(0 < startTime);
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
        _returnWeb3FunctionArgsHex(address(this), gameID, startTime)
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
    uint256 homeTeamID,
    uint256 awayTeamID,
    uint256 pointAmount,
    uint256 startTime
  ) public payable {
    require(msg.sender == tx.origin);
    require(0 < startTime);
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
        _returnWeb3FunctionArgsHex(address(this), gameID, startTime)
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
        0,
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
    transaction.teamID = 0;
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
      uint256 stake = msgValue / newMoneyLineBet[gameID].teamTotal[winnerID];
      if (!checkSender(winningUserID)) {
        winningUserID.transfer(newMoneyLineBet[gameID].total * stake);
      }
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
    int winnerScore,
    int loserScore
  ) public onlyDedicatedMsgSender {
    address payable[] memory winners;
    uint winnersPurse = 0;
    uint winnersCount = 0;
    for (uint i = 0; i < newPointSpreadBet[gameID].usersArray.length; i++) {
      address payable currentUserID = newPointSpreadBet[gameID].usersArray[i];
      uint256 msgValue = newPointSpreadBet[gameID]
        .receipt[currentUserID]
        .amount;
      int spread = newPointSpreadBet[gameID].spreadAmount[currentUserID];
      if (winnerScore + spread > loserScore && !checkSender(currentUserID)) {
        winners[winnersCount] = currentUserID;
        winnersCount++;
        winnersPurse += msgValue;
      }
      userReceipts[currentUserID].escrow -= msgValue;
      for (uint x = 0; x < userReceipts[currentUserID].receipts.length; x++) {
        Transaction memory myArray = userReceipts[currentUserID].receipts[x];
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
    for (uint b = 0; b < winners.length; b++) {
      uint256 msgValue = newPointSpreadBet[gameID].receipt[winners[b]].amount;
      uint256 share = msgValue / winnersPurse;
      winners[b].transfer(newPointSpreadBet[gameID].total * share);
    }
  }

  function rewardPointTotalWinners(
    uint256 gameID,
    uint256 total
  ) public onlyDedicatedMsgSender {
    address payable[] memory winners;
    uint winnersPurse = 0;
    uint winnersCount = 0;
    uint drawTotal = 0;
    for (uint i = 0; i < newPointTotalBet[gameID].usersArray.length; i++) {
      address payable currentUserID = newPointTotalBet[gameID].usersArray[i];
      uint256 msgValue = newPointTotalBet[gameID].receipt[currentUserID].amount;
      if (
        total > newPointTotalBet[gameID].pointAmount[currentUserID] &&
        !checkSender(currentUserID)
      ) {
        winners[winnersCount] = currentUserID;
        winnersCount++;
        winnersPurse += msgValue;
      } else if (
        total == newPointTotalBet[gameID].pointAmount[currentUserID] &&
        !checkSender(currentUserID)
      ) {
        drawTotal += msgValue;
        currentUserID.transfer(msgValue);
      }
      userReceipts[currentUserID].escrow -= msgValue;

      for (uint x = 0; x < userReceipts[currentUserID].receipts.length; x++) {
        Transaction memory myArray = userReceipts[currentUserID].receipts[x];
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
      uint256 share = msgValue / (winnersPurse - drawTotal);
      winners[b].transfer((newPointTotalBet[gameID].total - drawTotal) * share);
    }
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

  function deposit() public payable {
    _depositFunds1Balance(msg.value, ETH, admin);
  }
}
