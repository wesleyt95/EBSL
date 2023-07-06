// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import 'contracts/Bet.sol';
import 'contracts/IResolver.sol';

abstract contract MoneyLineResolver is IResolver {
  Bet public betContract;

  constructor(address contractAddress) {
    betContract = Bet(contractAddress);
  }

  function checker(
    uint256 currentGameID
  ) external view returns (bool canExec, bytes memory execPayload) {
    if (block.timestamp > betContract.returnMoneyLineStartTime(currentGameID)) {
      bytes4 selector = betContract.rewardMoneyLineWinners.selector;
      execPayload = abi.encodeWithSelector(selector, currentGameID);
      canExec = true;
      return (canExec, execPayload);
    }
  }
}
