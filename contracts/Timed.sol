pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract Timed is Ownable {

	bool started;
	uint256 private startTime;
  	uint256 private duration;

  	// now is less than duration after start time - so we are still live
	modifier isOngoing() {
		require(startTime + duration > now);
		_;
	}

	// now is more than duration after start time - so we are dead
	modifier isClosed() {
		require(startTime + duration <= now);
		_;
	}

  	constructor(uint256 _start, uint256 _duration) public {
  		startTime = _start;
  		duration = _duration;
  	}


}