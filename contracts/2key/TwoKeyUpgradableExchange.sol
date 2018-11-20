pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract TwoKeyUpgradableExchange is Crowdsale {

	TwoKeyUpgradableExchange filler;

	/// @notice Event is emitted when a user sell his tokens
	event TokenSell(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


	modifier onlyAlive() {
		require(filler == address(0));
		_;
	}

	modifier onlyAdmin() {
		require(msg.sender == address(admin));
		_;
	}


	constructor(uint256 _rate, address _twoKeyAdmin, ERC20 _token)
		Crowdsale(_rate, _twoKeyAdmin, _token) public {
	}

    function () public payable {
        buyTokens(msg.sender);
    }

	/// @notice Function to fetch value of tokens in Wei.
    /// @dev It is an internal method
    /// @param _tokenAmount is amount of tokens
    /// @return Value of tokens in Wei
	function _getWeiAmount(uint256 _tokenAmount) internal view returns (uint256) {
	   return _tokenAmount.div(rate);
	}

	/// @notice Function where only admin can upgrade exchange contract with new exchange contract. 
    /// @dev This method is called only when alive (i.e. not upgraded to newExchange) and by admin
    /// @param _to is address of New Exchange Contract
	function upgrade(address _to) public onlyAlive onlyAdmin {
		filler = TwoKeyUpgradableExchange(_to);		// check if the address is exchange contract address -- add typecast
	}


	function getFiller() view public returns(address) {
		return filler;	
	}

}
