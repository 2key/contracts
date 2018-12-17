pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/math/SafeMath.sol';
import './TwoKeyEventSource.sol';
import "./ArcERC20.sol";

contract TwoKeyCampaignARC is ArcERC20 {

	using SafeMath for uint256;
	address public contractor;
    address public moderator;

	uint256 totalSupply_ = 1000000;

	TwoKeyEventSource twoKeyEventSource;

	uint256 conversionQuota;  // maximal ARC tokens that can be passed in transferFrom

	// referral graph, who did you receive the referral from
	mapping(address => address) public received_from;

    // @notice Modifier which allows only contractor to call methods
    modifier onlyContractor() {
        require(msg.sender == contractor);
        _;
    }

    // @notice Modifier which allows only moderator to call methods
    modifier onlyModerator() {
        require(msg.sender == moderator);
        _;
    }

    // @notice Modifier which allows only contractor or moderator to call methods
    modifier onlyContractorOrModerator() {
        require(msg.sender == contractor || msg.sender == moderator);
        _;
    }

    constructor(address _twoKeyEventSource, uint256 _conversionQuota) ArcERC20() public {
		require(_twoKeyEventSource != address(0));
		twoKeyEventSource = TwoKeyEventSource(_twoKeyEventSource);
		conversionQuota = _conversionQuota;
		balances[msg.sender] = totalSupply_;
	}

	/**
	 * @dev transfer token for a specified address
	 * @param _to The address to transfer to.
	 * @param _value The amount to be transferred.
	 */
	function transferQuota(address _to, uint256 _value) private returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value * conversionQuota);
		totalSupply_ = totalSupply_.add(_value.mul(conversionQuota - 1));
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	 * @dev Transfer tokens from one address to another
	 * @param _from address The address which you want to send tokens from
	 * @param _to address The address which you want to transfer to
	 * @param _value uint256 the amount of tokens to be transferred
	 */
	function transferFromQuota(address _from, address _to, uint256 _value) private returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value * conversionQuota);
		totalSupply_ = totalSupply_.add(_value.mul(conversionQuota - 1));
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}
	/// @notice Function where contractor or moderator can take arcs from user (remove)
	/// @dev only contractor or moderator can call this function, otherwise it will revert
	/// @param _user is the address of user we're taking arcs from
	/// @param _arcsAmount is the amount of arcs we're taking from the user
	function removeArcsFromUser(address _user, uint _arcsAmount) public onlyContractorOrModerator {
		require(_user != address(0));
		require(_arcsAmount > 0);
		if(balances[_user] < _arcsAmount) {
			balances[_user] = 0;
		} else {
			balances[_user].sub(_arcsAmount);
		}
		//Get back this arcs to contractor or otherwise remove from totalSupply
		balances[contractor].add(_arcsAmount);
	}

	/// @notice Function where contractor or moderator can give arcs to user
	/// @dev only contractor or moderator can call this function, otherwise it will revert
	/// @param _user is the address of the user who are we willing to give arcs
	/// @param _arcsAmount is the value how many arcs we're giving him
    function addArcsToUser(address _user, uint _arcsAmount) public onlyContractorOrModerator {
       require(_user != address(0));
       require(_arcsAmount > 0);
       balances[_user].add(_arcsAmount);
       totalSupply_.add(_arcsAmount);
     }
	
	/**
	   * @dev Transfer tokens from one address to another
	   * @param _from address The address which you want to send tokens from
	   * @param _to address The address which you want to transfer to
	   * @param _value uint256 the amount of tokens to be transferred
	   */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_value == 1);
		require(received_from[_to] == 0); // This line makes us sure we're in the tree
		require(_from != address(0));
		allowed[_from][msg.sender] = 1;
		if (transferFromQuota(_from, _to, _value)) {
			if (received_from[_to] == 0) {
				// inform the 2key admin contract, once, that an influencer has joined
//				twoKeyEventSource.joined(address(this), _from, _to);
			}
			received_from[_to] = _from;
			return true;
		} else {
			return false;
		}
	}

	/**
	  * @dev transfer token for a specified address
	  * @param _to The address to transfer to.
	  * @param _value The amount to be transferred.
	  */
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(received_from[_to] == 0);
		if (transferQuota(_to, _value)) {
			if (received_from[_to] == 0) {
				// inform the 2key admin contract, once, that an influencer has joined
//				twoKeyEventSource.joined(address(this), msg.sender, _to);
			}
			received_from[_to] = msg.sender;
			return true;
		} else {
			return false;
		}
	}


	function getReferrers(address customer) internal view returns (address[]) {
		// build a list of all influencers from converter back to to contractor
		// dont count the conveter and contractr themselves
		address influencer = customer;
		// first count how many influencers
		uint n_influencers = 0;
		while (true) {
			influencer = received_from[influencer];
			// Owner is owner of campaign (contractor)
			if (influencer == contractor) {
				break;
			}
			n_influencers++;
		}
		// allocate temporary memory to hold the influencers
		address[] memory influencers = new address[](n_influencers);
		// fill the array of influencers in reverse order, from the last influencer just before the converter to the
		// first influencer just after the contractor
		influencer = customer;
		while (n_influencers > 0) {
			influencer = received_from[influencer];
			n_influencers--;
			influencers[n_influencers] = influencer;
		}

		return influencers;
	}

}
