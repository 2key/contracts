pragma solidity ^0.4.24;

import "./ArcERC20.sol";

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/IUpgradableExchange.sol";

import "../singleton-contracts/TwoKeyEventSource.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Call.sol";

contract TwoKeyCampaign is ArcERC20 {


	using SafeMath for uint256;
	using Call for *;

	TwoKeyEventSource twoKeyEventSource;
	address public twoKeySingletonesRegistry;

	address public contractor; //contractor address
    address public moderator; //moderator address
	address public ownerPlasma; //contractor plasma address

	uint256 totalBounty; //Total bounty distributed to referrers ever
	uint256 contractorBalance; // Contractor balance
    uint256 contractorTotalProceeds; // Contractor total earnings
	uint256 maxReferralRewardPercent; // maxReferralRewardPercent is actually bonus percentage in ETH
	uint256 conversionQuota;  // maximal ARC tokens that can be passed in transferFrom
    uint256 moderatorBalanceETHWei; //Balance of the moderator which can be withdrawn
	uint256 moderatorTotalEarningsETHWei; //Total earnings of the moderator all time


    mapping(address => uint256) internal referrerPlasma2cut; // Mapping representing how much are cuts in percent(0-100) for referrer address
	mapping(address => uint256) internal referrerPlasma2BalancesEthWEI; // balance of EthWei for each influencer that he can withdraw
	mapping(address => uint256) internal referrerPlasma2TotalEarningsEthWEI; // Total earnings for referrers
	mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
	mapping(address => mapping(uint256 => uint256)) referrerPlasma2EarningsPerConversion;

	mapping(address => address) public public_link_key;
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
     * @notice Private function to set public link key to plasma address
     * @param me is the ethereum address
     * @param new_public_key is the new key user want's to set as his public key
     */
    function setPublicLinkKeyOf(address me, address new_public_key) internal {
        me = twoKeyEventSource.plasmaOf(me);
        require(balanceOf(me) > 0,'no ARCs');
        address old_address = public_link_key[me];
        if (old_address == address(0)) {
            public_link_key[me] = new_public_key;
        } else {
            require(old_address == new_public_key,'public key can not be modified');
        }
        public_link_key[me] = new_public_key;
    }

	/**
 	 * @notice Function which will unpack signature and get referrers, keys, and weights from it
 	 * @param sig is signature
 	 */
	function getInfluencersKeysAndWeightsFromSignature(bytes sig) internal returns (address[],address[],uint8[],address) {
		// move ARCs and set public_link keys and weights/cuts based on signature information
		// returns the last address in the sig

		// sig structure:
		// 1 byte version 0 or 1
		// 20 bytes are the address of the contractor or the influencer who created sig.
		//  this is the "anchor" of the link
		//  It must have a public key aleady stored for it in public_link_key
		// Begining of a loop on steps in the link:
		// * 65 bytes are step-signature using the secret from previous step
		// * message of the step that is going to be hashed and used to compute the above step-signature.
		//   message length depend on version 41 (version 0) or 86 (version 1):
		//   * 1 byte cut (percentage) each influencer takes from the bounty. the cut is stored in influencer2cut or weight for voting
		//   * 20 bytes address of influencer (version 0) or 65 bytes of signature of cut using the influencer address to sign
		//   * 20 bytes public key of the last secret
		// In the last step the message can be optional. If it is missing the message used is the address of the sender
		address old_address;
		/**
           old address -> plasma address
           old key -> publicLinkKey[plasma]
         */
		assembly
		{
			old_address := mload(add(sig, 21))
		}

		old_address = twoKeyEventSource.plasmaOf(old_address);
		address old_key = public_link_key[old_address];

		address[] memory influencers;
		address[] memory keys;
		uint8[] memory weights;
		(influencers, keys, weights) = Call.recoverSig(sig, old_key, twoKeyEventSource.plasmaOf(msg.sender));

		// check if we exactly reached the end of the signature. this can only happen if the signature
		// was generated with free_join_take and in this case the last part of the signature must have been
		// generated by the caller of this method
		require(// influencers[influencers.length-1] == msg.sender ||
			influencers[influencers.length-1] == twoKeyEventSource.plasmaOf(msg.sender) ||
			contractor == msg.sender,'only the contractor or the last in the link can call transferSig');

		return (influencers, keys, weights, old_address);
	}

    /**
     * @notice Function to set public link key
     * @param new_public_key is the new public key
     */
    function setPublicLinkKey(address new_public_key) public {
        setPublicLinkKeyOf(msg.sender, new_public_key);
    }

	/**
     * @notice Function to get cut for an (ethereum) address
     * @param me is the ethereum address
     */
	function getReferrerCut(address me) public view returns (uint256) {
		return referrerPlasma2cut[twoKeyEventSource.plasmaOf(me)];
	}

	/**
 	 * @notice Function to set cut of
 	 * @param me is the address (ethereum)
 	 * @param cut is the cut value
 	 */
	function setCutOf(address me, uint256 cut) internal {
		// what is the percentage of the bounty s/he will receive when acting as an influencer
		// the value 255 is used to signal equal partition with other influencers
		// A sender can set the value only once in a contract
		address plasma = twoKeyEventSource.plasmaOf(me);
		require(referrerPlasma2cut[plasma] == 0 || referrerPlasma2cut[plasma] == cut, 'cut already set differently');
		referrerPlasma2cut[plasma] = cut;
	}

	/**
     * @notice Function to set cut
     * @param cut is the cut value
     * @dev Executes internal setCutOf method
     */
	function setCut(uint256 cut) public {
		setCutOf(msg.sender, cut);
	}


	/**
     * @notice Function to update maxReferralRewardPercent
     * @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
     * @param value is the new referral percent value
     */
	function updateMaxReferralRewardPercent(uint value) external onlyContractor {
		maxReferralRewardPercent = value;
		twoKeyEventSource.updatedData(block.timestamp, value, "Updated maxReferralRewardPercent");
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

    /**
     * @notice Function to return the constants from the contract
     */
    function getConstantInfo() public view returns (uint,uint) {
        return (conversionQuota, maxReferralRewardPercent);
    }

    /**
     * @notice Function to fetch moderator balance in ETH and his total earnings
     * @dev only contractor or moderator are eligible to call this function
     * @return value of his balance in ETH
     */
    function getModeratorBalanceAndTotalEarnings() external view returns (uint,uint) {
        require(msg.sender == contractor);
        return (moderatorBalanceETHWei,moderatorTotalEarningsETHWei);
    }

    /**
     * @notice Function to fetch contractor balance in ETH
     * @dev only contractor can call this function, otherwise it will revert
     * @return value of contractor balance in ETH WEI
     */
    function getContractorBalanceAndTotalProceeds() external onlyContractor view returns (uint,uint) {
        return (contractorBalance, contractorTotalProceeds);
    }

	/**
 	 * @notice Private function which will be executed at the withdraw time to buy 2key tokens from upgradable exchange contract
 	 * @param amountOfMoney is the ether balance person has on the contract
 	 * @param receiver is the address of the person who withdraws money
 	 */
	function buyTokensFromUpgradableExchange(uint amountOfMoney, address receiver) internal {
		address upgradableExchange = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonesRegistry).getContractProxyAddress("TwoKeyUpgradableExchange");
		IUpgradableExchange(upgradableExchange).buyTokens.value(amountOfMoney)(receiver);
	}

    /**
     * @notice Function where contractor can withdraw his funds
     * @dev onlyContractor can call this method
     * @return true if successful otherwise will 'revert'
     */
    function withdrawContractor() external onlyContractor {
        uint balance = contractorBalance;
        contractorBalance = 0;
        /**
         * In general transfer by itself prevents against reentrancy attack since it will throw if more than 2300 gas
         * but however it's not bad to practice this pattern of firstly reducing balance and then doing transfer
         */
        contractor.transfer(balance);
    }

	/**
 	 * @notice Function where moderator or referrer can withdraw their available funds
 	 * @param _address is the address we're withdrawing funds to
 	 * @dev It can be called by the address specified in the param or by the one of two key maintainers
 	 */
	function withdrawModeratorOrReferrer(address _address) external {
		require(msg.sender == _address || twoKeyEventSource.isAddressMaintainer(msg.sender));
		uint balance;
		if(_address == moderator) {
			address twoKeyDeepFreezeTokenPool = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonesRegistry).getContractProxyAddress("TwoKeyDeepFreezeTokenPool");
			uint integratorFee = twoKeyEventSource.getTwoKeyDefaultIntegratorFeeFromAdmin();
			balance = moderatorBalanceETHWei.mul(100-integratorFee).div(100);
			uint networkFee = moderatorBalanceETHWei.mul(integratorFee).div(100);
			moderatorBalanceETHWei = 0;
			buyTokensFromUpgradableExchange(balance,_address);
			buyTokensFromUpgradableExchange(networkFee,twoKeyDeepFreezeTokenPool);
		} else {
			address _referrer = twoKeyEventSource.plasmaOf(_address);
			if(referrerPlasma2BalancesEthWEI[_referrer] != 0) {
				balance = referrerPlasma2BalancesEthWEI[_referrer];
				referrerPlasma2BalancesEthWEI[_referrer] = 0;
				buyTokensFromUpgradableExchange(balance, _address);
			} else {
				revert();
			}
		}
	}

}
