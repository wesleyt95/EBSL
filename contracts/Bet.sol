// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import 'https://github.com/gelatodigital/automate/blob/master/contracts/integrations/AutomateTaskCreator.sol';
import 'https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/ChainlinkClient.sol';
import 'https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/ConfirmedOwner.sol';

abstract contract Bet is AutomateTaskCreator, ChainlinkClient, ConfirmedOwner {
  using Chainlink for Chainlink.Request;
  address payable admin;
  bytes32 private jobId;
  uint256 private fee;
  address moneyLineResolverAddress;

  constructor() ConfirmedOwner(msg.sender) {
    admin = payable(msg.sender);
    setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
    jobId = 'ca98366cc7314957b8c012c72f05aeeb';
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
    bytes32 indexed requestId,
    uint256 game,
    uint256 home,
    uint256 visitor
  );

  function uint2str(uint256 _i) internal pure returns (string memory str) {
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
    str = string(bstr);
  }

  function requestMultipleParameters(uint256 currentGameID) public {
    Chainlink.Request memory req = buildChainlinkRequest(
      jobId,
      address(this),
      this.fulfillMultipleParameters.selector
    );

    string memory url = string.concat(
      'https://www.balldontlie.io/api/v1/games/',
      uint2str(currentGameID)
    );
    req.add('urlGame', url);
    req.add('pathGame', 'id');
    req.add('urlHome', url);
    req.add('pathHome', 'home_team_score');
    req.add('urlVisitor', url);
    req.add('pathVisitor', 'visitor_team_score');
    sendChainlinkRequest(req, fee); // MWR API.
  }

  function fulfillMultipleParameters(
    bytes32 requestId,
    uint256 gameResponse,
    uint256 homeResponse,
    uint256 visitorResponse
  ) public recordChainlinkFulfillment(requestId) {
    emit RequestMultipleFulfilled(
      requestId,
      gameResponse,
      homeResponse,
      visitorResponse
    );
    home_team_score[gameResponse] = homeResponse;
    visitor_team_score[gameResponse] = visitorResponse;
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
        moneyLineResolverAddress,
        abi.encodeWithSelector(
          bytes4(keccak256(bytes('checker(uint256)'))),
          (gameID)
        )
      );
      moduleData.args[1] = _proxyModuleArg();
      moduleData.args[2] = _singleExecModuleArg();
      address executor = 0x683913B3A32ada4F8100458A3E1675425BdAa7DF;
      _createTask(
        executor,
        abi.encodeWithSelector(this.rewardMoneyLineWinners.selector, (gameID)),
        moduleData,
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
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

  function pointSpreadBet(
    address user,
    uint256 gameID,
    uint256 teamID,
    uint256 homeTeamID,
    uint256 awayTeamID,
    uint256 startTime,
    int spread
  ) public payable {
    require(homeTeamID != awayTeamID);
    require(msg.sender == user, 'You must bet from your own address');
    require(msg.value > 0, 'You must bet something');
    require(
      teamID == homeTeamID || teamID == awayTeamID,
      'You must bet on a team that is playing in this game'
    );
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
        block.timestamp
      )
    );
    totalBetOnGame[gameID] += msg.value;
    totalBetOnTeam[gameID][teamID] += msg.value;
    pointSpread.total += msgValue;
    pointSpread.teamTotal[teamID] += msgValue;
    pointSpread.homeTeamID = homeTeamID;
    pointSpread.awayTeamID = awayTeamID;
    pointSpread.startTime = startTime;
    pointSpread.spreadAmount[teamID] = spread;
    if (
      newPointSpreadBet[gameID].receipt[teamID][msg.sender].addr != msg.sender
    ) {
      usersArray.push(payable(msg.sender));
    }
    transaction.addr = msg.sender;
    transaction.amount += msgValue;
    transaction.teamID = teamID;
    transaction.gameID = gameID;
    transaction.betType = 'Point Spread';
    transaction.time = block.timestamp;
  }

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

  function returnMoneyLineUsersArray(
    uint256 gameID,
    uint256 teamID
  ) public view returns (address payable[] memory) {
    return newMoneyLineBet[gameID].usersArray[teamID];
  }

  function returnMoneyLineStartTime(
    uint256 gameID
  ) public view returns (uint256) {
    return newMoneyLineBet[gameID].startTime;
  }

  function returnPointSpreadUsersArray(
    uint256 gameID,
    uint256 teamID
  ) public view returns (address payable[] memory) {
    return newPointSpreadBet[gameID].usersArray[teamID];
  }

  function returnPointTotalUsersArray(
    uint256 gameID,
    int value
  ) public view returns (address payable[] memory) {
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

  function setMoneyLineResolverAddress(address addr) public {
    require(msg.sender == admin, 'You are not the admin');
    moneyLineResolverAddress = addr;
  }

  function transferEther() public {
    require(msg.sender == admin, 'You are not the admin');
    admin.transfer(address(this).balance);
  }
}
