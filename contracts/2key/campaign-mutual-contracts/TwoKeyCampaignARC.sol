pragma solidity ^0.4.24;

import "../singleton-contracts/TwoKeyEventSource.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../libraries/SafeMath.sol";
import "../acquisition-campaign-contracts/ArcERC20.sol";

contract TwoKeyCampaignARC is ArcERC20 {

	using SafeMath for uint256;

	TwoKeyEventSource twoKeyEventSource;
	address public twoKeySingletonesRegistry;

	address public contractor; //contractor address
    address public moderator; //moderator address
	address public ownerPlasma; //contractor plasma address

	uint moderatorBalanceETHWei; //Balance of the moderator which can be withdrawn
	uint moderatorTotalEarningsETHWei; //Total earnings of the moderator all time


    mapping(address => uint256) internal referrerPlasma2cut; // Mapping representing how much are cuts in percent(0-100) for referrer address
	mapping(address => uint256) internal referrerPlasma2BalancesEthWEI; // balance of EthWei for each influencer that he can withdraw
	mapping(address => uint256) internal referrerPlasma2TotalEarningsEthWEI; // Total earnings for referrers
	mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
	mapping(address => mapping(uint => uint)) referrerPlasma2EarningsPerConversion;
	mapping(address => address) public public_link_key;


	uint256 maxReferralRewardPercent; // maxReferralRewardPercent is actually bonus percentage in ETH
	uint256 conversionQuota;  // maximal ARC tokens that can be passed in transferFrom
	mapping(address => address) internal received_from; // referral graph, who did you receive the referral from


    // @notice Modifier which allows only contractor to call methods
    modifier onlyContractor() {
        require(msg.sender == contractor);
        _;
    }

	/**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from ALREADY converted to plasma
     * @param _to address The address which you want to transfer to ALREADY converted to plasma
     * @param _value uint256 the amount of tokens to be transferred
     */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		//Add modifier who can call this!! onlyContractorOrModerator || msg.sender == from something like this
		return transferFromInternal(_from, _to, _value);
	}

	function transferFromInternal(address _from, address _to, uint256 _value) internal returns (bool) {
		// _from and _to are assumed to be already converted to plasma address (e.g. using plasmaOf)
		require(_value == 1, 'can only transfer 1 ARC');
		require(_from != address(0), '_from undefined');
		require(_to != address(0), '_to undefined');

		//Addresses are already plasma, don't see the point of next 2 lines!
		_from = twoKeyEventSource.plasmaOf(_from);
		_to = twoKeyEventSource.plasmaOf(_to);

		require(balances[_from] > 0,'_from does not have arcs');
		balances[_from] = balances[_from].sub(1);
		balances[_to] = balances[_to].add(conversionQuota);
		totalSupply_ = totalSupply_.add(conversionQuota.sub(1));

		emit Transfer(_from, _to, 1);
		if (received_from[_to] == 0) {
			// inform the 2key admin contract, once, that an influencer has joined
			twoKeyEventSource.joined(this, _from, _to);
		}
		received_from[_to] = _from;
		return true;
	}

	/**
	 * @notice Getter for the referral chain
	 * @param _receiver is address we want to check who he has received link from
	 */
	function getReceivedFrom(address _receiver) public view returns (address) {
		return received_from[_receiver];
	}


	/**
     * @notice Function to get public link key of an address
     * @param me is the address we're checking public link key
     */
	function publicLinkKeyOf(address me) public view returns (address) {
		return public_link_key[twoKeyEventSource.plasmaOf(me)];
	}



}
