// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
import {AutomateTaskCreator} from './AutomateTaskCreator.sol';
import {Module, ModuleData} from './Types.sol';
import {ChainlinkClient} from '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import {Chainlink} from '@chainlink/contracts/src/v0.8/Chainlink.sol';
import {ConfirmedOwner} from '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

contract Bet is AutomateTaskCreator, ChainlinkClient, ConfirmedOwner {
  using Chainlink for Chainlink.Request;
  address payable admin;
  bytes32 private jobId;
  uint256 private fee;
<<<<<<< HEAD
=======
  address moneyLineResolverAddress;
>>>>>>> parent of ca29b0f (Updated...small details)

  constructor()
    AutomateTaskCreator(
      0xc1C6805B857Bef1f412519C4A842522431aFed39,
      address(this)
    )
    ConfirmedOwner(msg.sender)
  {
    admin = payable(msg.sender);
    setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    setChainlinkOracle(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434);
    jobId = '437d298d210c4fff935dcedb97ea8011';
    fee = (1 * LINK_DIVISIBILITY) / 10;
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
  }
  struct MoneyLine {
    uint256 startTime;
    uint256 total;
    mapping(uint256 => uint256) teamTotal;
    uint256 homeTeamID;
    uint256 awayTeamID;
    mapping(uint256 => address payable[]) usersArray;
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
    mapping(uint256 => address payable[]) usersArray;
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
    mapping(int => address payable[]) usersArray;
    mapping(int => mapping(address => Transaction)) receipt;
    int result;
  }

  mapping(address => User) public userReceipts;
  mapping(uint256 => uint256) public totalBetOnGame;
  mapping(uint256 => mapping(uint256 => uint256)) public totalBetOnTeam;
  mapping(uint256 => MoneyLine) public newMoneyLineBet;
  mapping(uint256 => PointSpread) public newPointSpreadBet;
  mapping(uint256 => PointTotal) public newPointTotalBet;
  mapping(uint256 => uint256) public visitor_team_score;
  mapping(uint256 => uint256) public home_team_score;

  event RequestMultipleFulfilled(
    bytes32 requestId,
    uint256 indexed id,
    uint256 indexed home_team_score,
    uint256 indexed visitor_team_score
  );

  function uint256ToString(uint256 _i) public pure returns (string memory) {
    if (_i == 0) {
      return '0';
    }
    uint256 j = _i;
    uint256 length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = uint8(48 + (_i % 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function requestMultipleParameters(uint256 currentGameID) public {
    Chainlink.Request memory req = buildChainlinkRequest(
      jobId,
      address(this),
      this.fulfillMultipleParameters.selector
    );
    string memory gameIdString = uint256ToString(currentGameID);
    string memory url = string.concat(
      'https://www.balldontlie.io/api/v1/games/',
      gameIdString
    );
    req.add('get', url);
    req.add('path1', 'id');
    req.add('path2', 'home_team_score');
    req.add('path3', 'visitor_team_score');
    req.addInt('times', 1);
    sendChainlinkRequest(req, fee); // MWR API.
  }

  function fulfillMultipleParameters(
    bytes32 requestId,
    uint256 idResponse,
    uint256 home_team_scoreResponse,
    uint256 visitor_team_scoreResponse
  ) public recordChainlinkFulfillment(requestId) {
    emit RequestMultipleFulfilled(
      requestId,
      idResponse,
      home_team_scoreResponse,
      visitor_team_scoreResponse
    );
    home_team_score[idResponse] = home_team_scoreResponse;
    visitor_team_score[idResponse] = visitor_team_scoreResponse;
  }

  function returnOdds(
    uint256 gameID,
    uint256 bettingTeamID
  ) public view returns (uint256) {
    uint256 bettingTeam = totalBetOnTeam[gameID][bettingTeamID];
    uint256 gameTotal = totalBetOnGame[gameID];
    uint256 odds = (bettingTeam * 100) / gameTotal;
    return odds;
  }

  function moneyLineBet(
    address user,
    uint256 gameID,
    uint256 teamID,
    uint256 homeTeamID,
    uint256 awayTeamID,
    uint256 startTime
  ) public payable {
    require(homeTeamID != awayTeamID);
    require(msg.sender == user, 'You must bet from your own address');
    require(msg.value > 0, 'You must bet something');
    require(
      teamID == homeTeamID || teamID == awayTeamID,
      'You must bet on a team that is playing in this game'
    );
    if (newMoneyLineBet[gameID].total == 0) {
      ModuleData memory moduleData = ModuleData({
        modules: new Module[](3),
        args: new bytes[](3)
      });
      moduleData.modules[0] = Module.RESOLVER;
      moduleData.modules[1] = Module.PROXY;
      moduleData.modules[2] = Module.SINGLE_EXEC;
      moduleData.args[0] = _resolverModuleArg(
        address(this),
        abi.encodeCall(this.moneyLineChecker, (gameID))
      );
      moduleData.args[1] = _proxyModuleArg();
      moduleData.args[2] = _singleExecModuleArg();
<<<<<<< HEAD
=======
      address executor = 0x683913B3A32ada4F8100458A3E1675425BdAa7DF;
>>>>>>> parent of ca29b0f (Updated...small details)
      _createTask(
        address(this),
        abi.encodeWithSelector(this.rewardMoneyLineWinners.selector, (gameID)),
        moduleData,
        ETH
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
        block.timestamp
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
  }

  // function pointSpreadBet(
  //   address user,
  //   uint256 gameID,
  //   uint256 teamID,
  //   uint256 homeTeamID,
  //   uint256 awayTeamID,
  //   uint256 startTime,
  //   int spread
  // ) public payable {
  //   require(homeTeamID != awayTeamID);
  //   require(msg.sender == user, 'You must bet from your own address');
  //   require(msg.value > 0, 'You must bet something');
  //   require(
  //     teamID == homeTeamID || teamID == awayTeamID,
  //     'You must bet on a team that is playing in this game'
  //   );
  //   uint256 tax = (msg.value * 5) / 100;
  //   uint256 msgValue = (msg.value * 95) / 100;
  //   PointSpread storage pointSpread = newPointSpreadBet[gameID];
  //   Transaction[] storage receipt = userReceipts[msg.sender].receipts;
  //   Transaction storage transaction = pointSpread.receipt[teamID][msg.sender];
  //   address payable[] storage usersArray = pointSpread.usersArray[teamID];
  //   admin.transfer(tax);
  //   userReceipts[msg.sender].escrow += msgValue;
  //   receipt.push(
  //     Transaction(
  //       msg.sender,
  //       msgValue,
  //       teamID,
  //       gameID,
  //       'Point Spread',
  //       block.timestamp
  //     )
  //   );
  //   totalBetOnGame[gameID] += msg.value;
  //   totalBetOnTeam[gameID][teamID] += msg.value;
  //   pointSpread.total += msgValue;
  //   pointSpread.teamTotal[teamID] += msgValue;
  //   pointSpread.homeTeamID = homeTeamID;
  //   pointSpread.awayTeamID = awayTeamID;
  //   pointSpread.startTime = startTime;
  //   pointSpread.spreadAmount[teamID] = spread;
  //   if (
  //     newPointSpreadBet[gameID].receipt[teamID][msg.sender].addr != msg.sender
  //   ) {
  //     usersArray.push(payable(msg.sender));
  //   }
  //   transaction.addr = msg.sender;
  //   transaction.amount += msgValue;
  //   transaction.teamID = teamID;
  //   transaction.gameID = gameID;
  //   transaction.betType = 'Point Spread';
  //   transaction.time = block.timestamp;
  // }

  function pointTotalBet(
    address user,
    uint256 gameID,
    uint256 pointAmount,
    uint256 homeTeamID,
    uint256 awayTeamID,
    uint256 startTime,
    int value
  ) public payable {
    require(homeTeamID != awayTeamID);
    require(msg.sender == user, 'You must bet from your own address');
    require(msg.value > 0, 'You must bet something');
    uint256 tax = (msg.value * 5) / 100;
    uint256 msgValue = (msg.value * 95) / 100;
    PointTotal storage pointTotal = newPointTotalBet[gameID];
    Transaction[] storage receipt = userReceipts[msg.sender].receipts;
    Transaction storage transaction = pointTotal.receipt[value][msg.sender];
    address payable[] storage usersArray = pointTotal.usersArray[value];
    admin.transfer(tax);
    userReceipts[msg.sender].escrow += msgValue;
    receipt.push(
      Transaction(
        msg.sender,
        msgValue,
        0,
        gameID,
        'Point Total',
        block.timestamp
      )
    );
    totalBetOnGame[gameID] += msg.value;
    pointTotal.total += msgValue;
    pointTotal.betTotal[value] += msgValue;
    pointTotal.homeTeamID = homeTeamID;
    pointTotal.awayTeamID = awayTeamID;
    pointTotal.startTime = startTime;
    pointTotal.pointAmount = pointAmount;
    if (
      newPointTotalBet[gameID].receipt[value][msg.sender].addr != msg.sender
    ) {
      usersArray.push(payable(msg.sender));
    }
    transaction.addr = msg.sender;
    transaction.amount += msgValue;
    transaction.teamID = 0;
    transaction.gameID = gameID;
    transaction.betType = 'Point Total';
    transaction.time = block.timestamp;
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

  function returnEscrow() public view returns (uint256) {
    return userReceipts[msg.sender].escrow;
  }

  function returnReceipts() public view returns (Transaction[] memory) {
    return userReceipts[msg.sender].receipts;
  }

  function rewardMoneyLineWinners(
    uint256 gameID
  ) public onlyDedicatedMsgSender {
    uint256 teamID;
    uint256 losingTeamID;
    requestMultipleParameters(gameID);
    if (
      visitor_team_score[gameID] > 0 &&
      (visitor_team_score[gameID] > home_team_score[gameID])
    ) {
      teamID = newMoneyLineBet[gameID].awayTeamID;
      losingTeamID = newMoneyLineBet[gameID].homeTeamID;
    } else if (
      home_team_score[gameID] > 0 &&
      (home_team_score[gameID] > visitor_team_score[gameID])
    ) {
      teamID = newMoneyLineBet[gameID].homeTeamID;
      losingTeamID = newMoneyLineBet[gameID].awayTeamID;
    }
    for (
      uint i = 0;
      i < newMoneyLineBet[gameID].usersArray[teamID].length;
      i++
    ) {
      uint256 msgValue = newMoneyLineBet[gameID]
      .receipt[teamID][newMoneyLineBet[gameID].usersArray[teamID][i]].amount;
      newMoneyLineBet[gameID].usersArray[teamID][i].transfer(
        msgValue / newMoneyLineBet[gameID].total
      );
      userReceipts[newMoneyLineBet[gameID].usersArray[teamID][i]]
        .escrow -= msgValue;
    }
    for (
      uint i = 0;
      i < newMoneyLineBet[gameID].usersArray[losingTeamID].length;
      i++
    ) {
      uint256 msgValue = newMoneyLineBet[gameID]
      .receipt[losingTeamID][
        newMoneyLineBet[gameID].usersArray[losingTeamID][i]
      ].amount;
      userReceipts[newMoneyLineBet[gameID].usersArray[losingTeamID][i]]
        .escrow -= msgValue;
    }
  }

  function returnResponse(uint256 gameID) public returns (uint256) {
    requestMultipleParameters(gameID);
    return home_team_score[gameID];
  }

  function depositForCounter() external payable {
    require(msg.sender == admin, 'You are not the admin');
    _depositFunds(msg.value, ETH);
  }

  function moneyLineChecker(
    uint256 currentGameID
  ) external view returns (bool canExec, bytes memory execPayload) {
    if (block.timestamp > newMoneyLineBet[currentGameID].startTime) {
      execPayload = abi.encodeCall(this.rewardMoneyLineWinners, currentGameID);
      canExec = true;
      return (canExec, execPayload);
    }
  }
}
