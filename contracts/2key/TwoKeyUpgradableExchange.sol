pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import "./TwoKeyAdmin.sol";

contract TwoKeyUpgradableExchange is Crowdsale {

	TwoKeyUpgradableExchange filler;

	/// @notice Event is emitted when a user sell his tokens
	event TokenSell(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /// @notice Modifier will revert if filler is set to any address 
	modifier onlyAlive() {
		require(filler == address(0));
		_;
	}

	modifier onlyAdmin() {
		require(msg.sender == address(admin));
		_;
	}

	TwoKeyAdmin admin;


	constructor(uint256 _rate, address _wallet, ERC20 _token, address _twoKeyAdmin)
		Crowdsale(_rate, _wallet, _token) public {
		require(_twoKeyAdmin != address(0));
    	admin = TwoKeyAdmin(_twoKeyAdmin);
    	// admin.setTwoKeyExchange(address(this));	
    	
	}

    /// View function - doesn't cost any gas to be executed
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

    /// @notice It is a payable fallback method that will transfer payable amount to new Exchange if it is upgraded, else will be stored in the existing exchange as its balance
    function() external payable {
		if (filler != address(0))
			filler.transfer(msg.value);
	}

    /// @notice It is a payable function that allows user to buy tokens in exchange of their ethers (in Weis). 
    /// @dev This method is called only when alive (i.e. not upgraded to newExchange)
    /// @param _beneficiary is address of user where tokens will be transferred
	function buyTokens(address _beneficiary) public onlyAlive payable {
		super.buyTokens(_beneficiary);
	}

	function getFiller() view public returns(address) {
		return filler;	
	}
}
