pragma solidity ^0.4.24;

import "../singleton-contracts/TwoKeyEventSource.sol";
import "../interfaces/IUpgradableExchange.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyFeeManager.sol";
import "../interfaces/ITwoKeyDeepFreezeTokenPool.sol";
import "../interfaces/ITwoKeyCampaignLogicHandler.sol";
import "./TwoKeyCampaignAbstract.sol";
/**
 * @author Nikola Madjarevic (https://github.com/madjarevicn)
 */
contract TwoKeyCampaign is TwoKeyCampaignAbstract {

	TwoKeyEventSource twoKeyEventSource; // Address of TwoKeyEventSource contract

	address public conversionHandler; // Contract which will handle all conversions
	address public logicHandler;  // Contract which will handle logic

	address twoKeyEconomy; // Address of twoKeyEconomy contract
	address ownerPlasma; //contractor plasma address


	bool isKYCRequired; // Flag if KYC is required or not on this campaign
    bool mustConvertToReferr;


	uint256 contractorBalance; // Contractor balance
	uint256 contractorTotalProceeds; // Contractor total earnings
	uint256 moderatorTotalEarnings2key; //Total earnings of the moderator all time

	//Referral accounting stuff
	mapping(address => uint256) internal referrerPlasma2cut; // Mapping representing how much are cuts in percent(0-100) for referrer address


	/**
	 * @notice Modifier which will enable only twoKeyConversionHandlerContract to execute some functions
	 */
	modifier onlyTwoKeyConversionHandler {
		require(msg.sender == conversionHandler);
		_;
	}

	/**
	 * @notice Modifier to restrict access to logic handler for specific methods
	 */
	modifier onlyTwoKeyLogicHandler {
		require(msg.sender == logicHandler);
		_;
	}

	modifier onlyMaintainer {
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
		require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
		_;
	}

	/**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from ALREADY converted to plasma
     * @param _to address The address which you want to transfer to ALREADY converted to plasma
     * @param _value uint256 the amount of tokens to be transferred
     */
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
	internal
	{
		require(balances[_from] > 0);

		balances[_from] = balances[_from].sub(1);
		balances[_to] = balances[_to].add(conversionQuota);
		totalSupply_ = totalSupply_.add(conversionQuota.sub(1));

		twoKeyEventSource.joined(this, _from, _to);

		received_from[_to] = _from;
	}


    /**
     * @notice Private function to set public link key to plasma address
     * @param me is the ethereum address
     * @param new_public_key is the new key user want's to set as his public key
     */
    function setPublicLinkKeyOf(
		address me,
		address new_public_key
	)
	internal
	{
        me = twoKeyEventSource.plasmaOf(me);
        require(balanceOf(me) > 0);
        address old_address = public_link_key[me];
        if (old_address == address(0)) {
            public_link_key[me] = new_public_key;
        } else {
            require(old_address == new_public_key);
        }
        public_link_key[me] = new_public_key;
    }


	/**
 	 * @notice Function which will unpack signature and get referrers, keys, and weights from it
 	 * @param sig is signature
 	 */
	function getInfluencersKeysAndWeightsFromSignature(
		bytes sig,
		address _converter
	)
	internal
	view
	returns (address[],address[],uint8[],address)
	{
		// Recheck
//		require(sig != bytes(0)); // signature can't be empty
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

		address converterPlasma = twoKeyEventSource.plasmaOf(_converter);
		address[] memory influencers;
		address[] memory keys;
		uint8[] memory weights;
		(influencers, keys, weights) = Call.recoverSig(sig, old_key, converterPlasma);

		// check if we exactly reached the end of the signature. this can only happen if the signature
		// was generated with free_join_take and in this case the last part of the signature must have been
		// generated by the caller of this method
		require(
			influencers[influencers.length-1] == converterPlasma
		);

		return (influencers, keys, weights, old_address);
	}

	/**
	 * @notice 		Function to get number of influencers between submimtted user and contractor
	 * @param 		_user is the address of the user we're checking information
	 *
	 * 				Example: contractor -> user1 -> user2 -> user3
	 *				Result for input(user3) = 2
	 * @return		Difference between user -> contractor
	 */
	function getNumberOfUsersToContractor(
		address _user
	)
	public
	view
	returns (uint)
	{
		uint counter = 0;
		_user = twoKeyEventSource.plasmaOf(_user);
		while(received_from[_user] != ownerPlasma) {
			_user = received_from[_user];
			require(_user != address(0));
			counter ++;
		}
		return counter;
	}

	/**
	 * @notice Function to set cut of
	 * @param me is the address (ethereum)
	 * @param cut is the cut value
	 */
	function setCutOf(
		address me,
		uint256 cut
	)
	internal
	{
		// what is the percentage of the bounty s/he will receive when acting as an influencer
		// the value 255 is used to signal equal partition with other influencers
		// A sender can set the value only once in a contract
		address plasma = twoKeyEventSource.plasmaOf(me);
		require(referrerPlasma2cut[plasma] == 0 || referrerPlasma2cut[plasma] == cut);
		referrerPlasma2cut[plasma] = cut;
	}

	/**
	 * @notice Function to track arcs and make ref tree
	 * @param sig is the signature user joins from
	 */
	function distributeArcsBasedOnSignature(
		bytes sig,
		address _converter
	)
	internal
	{
		address[] memory influencers;
		address[] memory keys;
		uint8[] memory weights;
		address old_address;
		(influencers, keys, weights, old_address) = getInfluencersKeysAndWeightsFromSignature(sig, _converter);
		uint i;
		address new_address;
		uint numberOfInfluencers = influencers.length;
		require(numberOfInfluencers <= 40);
		for (i = 0; i < numberOfInfluencers; i++) {
			new_address = twoKeyEventSource.plasmaOf(influencers[i]);

			if (received_from[new_address] == 0) {
				transferFrom(old_address, new_address, 1);
			} else {
				require(received_from[new_address] == old_address);
			}

			old_address = new_address;

			if (i < keys.length) {
				setPublicLinkKeyOf(new_address, keys[i]);
			}

			if (i < weights.length) {
				setCutOf(new_address, uint256(weights[i]));
			}
		}
	}

	function calculateInfluencersFee(
		uint conversionAmount,
		uint numberOfInfluencers
	)
	internal
	view
	returns (uint)
	{
		if(numberOfInfluencers >= 1) {
			return conversionAmount.mul(maxReferralRewardPercent).div(100);
		}
		return 0;
	}

	/**
	 * @notice Function which will buy tokens from upgradable exchange for moderator
	 * @param moderatorFee is the fee in tokens moderator earned
	 */
	function buyTokensForModeratorRewards(
		uint moderatorFee
	)
	public
	onlyTwoKeyConversionHandler
	{
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
		// Get the total tokens bought
		uint totalTokens;
		(totalTokens,) = buyTokensFromUpgradableExchange(moderatorFee, twoKeyAdmin); // Buy tokens for moderator and twoKeyDeepFreezeTokenPool

		// Update moderator on received tokens so it can proceed distribution to TwoKeyDeepFreezeTokenPool
		ITwoKeyAdmin(twoKeyAdmin).updateReceivedTokensAsModerator(totalTokens);
	}



	function updateModeratorRewards(
		uint moderatorTokens
	)
	public
	{
		require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin"));

		// Update moderator earnings
		moderatorTotalEarnings2key = moderatorTotalEarnings2key.add(moderatorTokens);
	}



	/**
	 * @notice 		Function which will distribute arcs if that is necessary
	 *
	 * @param 		_converter is the address of the converter
	 * @param		signature is the signature user is converting with
	 *
	 * @return 		Distance between user and contractor
	 */
	function distributeArcsIfNecessary(
		address _converter,
		bytes signature
	)
	internal
	returns (uint)
	{
		if(received_from[twoKeyEventSource.plasmaOf(_converter)] == address(0)) {
			distributeArcsBasedOnSignature(signature, _converter);
		}
		return getNumberOfUsersToContractor(_converter);
	}


	/**
     * @notice Function to set or update public meta hash
     * @param _publicMetaHash is the hash of the campaign
     * @dev Only contractor can call this
     */
	function startCampaignWithInitialParams(
		string _publicMetaHash,
		string _privateMetaHash,
		address _publicKey
	)
	public
	onlyContractor
	{
		publicMetaHash = _publicMetaHash;
		privateMetaHash = _privateMetaHash;
		setPublicLinkKeyOf(msg.sender, _publicKey);
	}


	/**
     * @notice Function to update referrer plasma balance
     * @param _influencer is the plasma address of referrer
     * @param _balance is the new balance
     */
	function updateReferrerPlasmaBalance(
		address _influencer,
		uint _balance
	)
	public
	{
		require(msg.sender == logicHandler);
		referrerPlasma2Balances2key[_influencer] = referrerPlasma2Balances2key[_influencer].add(_balance);
	}

	/**
 	 * @notice Private function which will be executed at the withdraw time to buy 2key tokens from upgradable exchange contract
 	 * @param amountOfMoney is the ether balance person has on the contract
 	 * @param receiver is the address of the person who withdraws money
 	 */
	function buyTokensFromUpgradableExchange(
		uint amountOfMoney,
		address receiver
	)
	internal
	returns (uint,uint)
	{
		address upgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
		return IUpgradableExchange(upgradableExchange).buyTokens.value(amountOfMoney)(receiver);
	}


	function payFeesForUser(
		address _userAddress,
		uint _amount
	)
	internal
	returns (uint,uint)
	{
		address twoKeyFeeManager = getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager");
        address _userPlasma = twoKeyEventSource.plasmaOf(_userAddress);

		uint debt = ITwoKeyFeeManager(twoKeyFeeManager).getDebtForUser(_userPlasma);
		uint amountToPay = debt;
		uint updatedConversionAmount = _amount;
		if(debt > 0) {
			if (_amount > debt){
				if(_amount < 3 * debt) {
					amountToPay = debt / 2;
				}
			}
			else{
				amountToPay = _amount / 4;
			}
			ITwoKeyFeeManager(twoKeyFeeManager).payDebtWhenConvertingOrWithdrawingProceeds.value(amountToPay)(_userPlasma, amountToPay);
            updatedConversionAmount = _amount.sub(amountToPay);
		}
		else{
			amountToPay = 0;
		}
		return (updatedConversionAmount, amountToPay);
	}

	/**
	 * @notice Function to send ether back to converter if his conversion is cancelled
	 * @param _cancelledConverter is the address of cancelled converter
	 * @param _conversionAmount is the amount he sent to the contract
	 * @dev This function can be called only by conversion handler
	 */
	function sendBackEthWhenConversionCancelledOrRejected(
		address _cancelledConverter,
		uint _conversionAmount
	)
	public
	onlyTwoKeyConversionHandler
	{
		_cancelledConverter.transfer(_conversionAmount);
	}

	/**
     * @notice Function to get public link key of an address
     * @param me is the address we're checking public link key
     */
	function publicLinkKeyOf(
		address me
	)
	public
	view
	returns (address)
	{
		return public_link_key[twoKeyEventSource.plasmaOf(me)];
	}

    /**
     * @notice Function to return the constants from the contract
     */
    function getConstantInfo()
	public
	view
	returns (uint,uint,bool)
	{
        return (conversionQuota, maxReferralRewardPercent, isKYCRequired);
    }

//    function getModeratorTotalEarnings()
//	public
//	view
//	returns (uint)
//	{
//        return (moderatorTotalEarnings2key);
//    }

    /**
     * @notice Function to fetch contractor balance in ETH
     * @dev only contractor can call this function, otherwise it will revert
     * @return value of contractor balance in ETH WEI
     */
    function getContractorBalanceAndTotalProceeds()
	external
	view
	returns (uint,uint)
	{
        return (contractorBalance, contractorTotalProceeds);
    }



	/**
	 * @notice Function to get balance of influencer for his plasma address
	 * @param _influencer is the plasma address of influencer
	 * @return balance in wei's
	 */
	function getReferrerPlasmaBalance(
		address _influencer
	)
	public
	view
	returns (uint)
	{
		return (referrerPlasma2Balances2key[twoKeyEventSource.plasmaOf(_influencer)]);
	}

	/**
	 * @notice Function to get cut for an (ethereum) address
	 * @param me is the ethereum address
	 */
	function getReferrerCut(
		address me
	)
	public
	view
	returns (uint256)
	{
		return referrerPlasma2cut[twoKeyEventSource.plasmaOf(me)];
	}

	/**
     * @notice Function where contractor can withdraw his funds
     * @dev onlyContractor can call this method
     * @return true if successful otherwise will 'revert'
     */
	function withdrawContractorInternal()
	internal
	{
		require(contractorBalance > 0);
		uint balance = contractorBalance;
		contractorBalance = 0;
		(balance,) = payFeesForUser(msg.sender, balance);
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
	function referrerWithdrawInternal(
		address _address,
		bool _withdrawAsStable
	)
	internal
	{
		require(msg.sender == _address || twoKeyEventSource.isAddressMaintainer(msg.sender));
		address twoKeyAdminAddress;
		address twoKeyUpgradableExchangeContract;

		uint balance;
		address _referrer = twoKeyEventSource.plasmaOf(_address);

		if(referrerPlasma2Balances2key[_referrer] != 0) {
			twoKeyAdminAddress = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
			twoKeyUpgradableExchangeContract = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");

			balance = referrerPlasma2Balances2key[_referrer];
			referrerPlasma2Balances2key[_referrer] = 0;

			if(_withdrawAsStable == true) {
				IERC20(twoKeyEconomy).approve(twoKeyUpgradableExchangeContract, balance);
				// Send the eth address and balance
				IUpgradableExchange(twoKeyUpgradableExchangeContract).buyStableCoinWith2key(balance, _address);
			}
			else if (block.timestamp >= ITwoKeyAdmin(twoKeyAdminAddress).getTwoKeyRewardsReleaseDate()) {
				//Report that we're withdrawing 2key from network
				IUpgradableExchange(twoKeyUpgradableExchangeContract).report2KEYWithdrawnFromNetwork(balance);
				// Get the address of fee manager
				address twoKeyFeeManager = getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager");
				IERC20(twoKeyEconomy).approve(twoKeyFeeManager, balance);
				ITwoKeyFeeManager(twoKeyFeeManager).payDebtWith2Key(_address, _referrer, balance);
			}
			else {
				revert();
			}
			reservedAmount2keyForRewards = reservedAmount2keyForRewards.sub(balance);
		}
	}
}

