pragma solidity ^0.4.13;

contract TwoKeyConversionStates {
    enum ConversionState {PENDING_APPROVAL, APPROVED, EXECUTED, REJECTED, CANCELLED_BY_CONVERTER}
}

contract TwoKeyConverterStates {
    enum ConverterState {NOT_EXISTING, PENDING_APPROVAL, APPROVED, REJECTED}

    /// @notice Function to convert converter state to it's bytes representation (Maybe we don't even need it)
    /// @param state is conversion state
    /// @return bytes32 (hex) representation of state
    function convertConverterStateToBytes(
        ConverterState state
    )
    internal
    pure
    returns (bytes32)
    {
        if(ConverterState.NOT_EXISTING == state) {
            return bytes32("NOT_EXISTING");
        }
        else if(ConverterState.PENDING_APPROVAL == state) {
            return bytes32("PENDING_APPROVAL");
        }
        else if(ConverterState.APPROVED == state) {
            return bytes32("APPROVED");
        }
        else if(ConverterState.REJECTED == state) {
            return bytes32("REJECTED");
        }
    }
}

contract ArcToken {

    uint256 internal totalSupply_;

    mapping(address => uint256) internal balances;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

contract TwoKeyCampaignAbstract is ArcToken {

    using SafeMath for uint256;
    using Call for *;

    bool isCampaignInitialized; // Representing if campaign "constructor" was called

    address public TWO_KEY_SINGLETON_REGISTRY;

    uint256 maxReferralRewardPercent; // maxReferralRewardPercent is actually bonus percentage in ETH

    address public contractor; //contractor address
    address public moderator; //moderator address

    uint256 conversionQuota;  // maximal ARC tokens that can be passed in transferFrom
    uint256 reservedAmount2keyForRewards; //Reserved amount of 2key tokens for rewards distribution

    string public publicMetaHash; // Ipfs hash of json campaign object
    string public privateMetaHash; // Ipfs hash of json sensitive (contractor) information

    mapping(address => uint256) internal referrerPlasma2Balances2key; // balance of EthWei for each influencer that he can withdraw

    mapping(address => address) internal public_link_key;
    mapping(address => address) internal received_from; // referral graph, who did you receive the referral from


    // @notice Modifier which allows only contractor to call methods
    modifier onlyContractor() {
        require(msg.sender == contractor);
        _;
    }

    // Internal function to fetch address from TwoKeyRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
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
     * @notice Function to allow updating public meta hash
     * @param _newPublicMetaHash is the new meta hash
     */
    function updateIpfsHashOfCampaign(
        string _newPublicMetaHash
    )
    public
    onlyContractor
    {
        publicMetaHash = _newPublicMetaHash;
    }



    function setPublicLinkKeyOf(
        address me,
        address new_public_key
    )
    internal;

    /**
     * @notice Getter for the referral chain
     * @param _receiver is address we want to check who he has received link from
     */
    function getReceivedFrom(
        address _receiver
    )
    public
    view
    returns (address)
    {
        return received_from[_receiver];
    }



}

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

contract TwoKeyCampaignIncentiveModels {
    enum IncentiveModel {MANUAL, VANILLA_AVERAGE, VANILLA_AVERAGE_LAST_3X, VANILLA_POWER_LAW, NO_REFERRAL_REWARD}
}

contract IERC20 {
    function balanceOf(
        address whom
    )
    external
    view
    returns (uint);


    function transfer(
        address _to,
        uint256 _value
    )
    external
    returns (bool);


    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    external
    returns (bool);



    function approve(
        address _spender,
        uint256 _value
    )
    public
    returns (bool);



    function decimals()
    external
    view
    returns (uint);


    function symbol()
    external
    view
    returns (string);


    function name()
    external
    view
    returns (string);


    function freezeTransfers()
    external;


    function unfreezeTransfers()
    external;
}

contract IStructuredStorage {

    function setProxyLogicContractAndDeployer(address _proxyLogicContract, address _deployer) external;
    function setProxyLogicContract(address _proxyLogicContract) external;

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns(uint);
    function getString(bytes32 _key) external view returns(string);
    function getAddress(bytes32 _key) external view returns(address);
    function getBytes(bytes32 _key) external view returns(bytes);
    function getBool(bytes32 _key) external view returns(bool);
    function getInt(bytes32 _key) external view returns(int);
    function getBytes32(bytes32 _key) external view returns(bytes32);

    // *** Getter Methods For Arrays ***
    function getBytes32Array(bytes32 _key) external view returns (bytes32[]);
    function getAddressArray(bytes32 _key) external view returns (address[]);
    function getUintArray(bytes32 _key) external view returns (uint[]);
    function getIntArray(bytes32 _key) external view returns (int[]);
    function getBoolArray(bytes32 _key) external view returns (bool[]);

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setAddress(bytes32 _key, address _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // *** Setter Methods For Arrays ***
    function setBytes32Array(bytes32 _key, bytes32[] _value) external;
    function setAddressArray(bytes32 _key, address[] _value) external;
    function setUintArray(bytes32 _key, uint[] _value) external;
    function setIntArray(bytes32 _key, int[] _value) external;
    function setBoolArray(bytes32 _key, bool[] _value) external;

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteAddress(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
}

contract ITwoKeyAdmin {
    function getDefaultIntegratorFeePercent() public view returns (uint);
    function getDefaultNetworkTaxPercent() public view returns (uint);
    function getTwoKeyRewardsReleaseDate() external view returns(uint);
    function updateReceivedTokensAsModerator(uint amountOfTokens) public;
    function updateReceivedTokensAsModeratorPPC(uint amountOfTokens, address campaignPlasma) public;
    function addFeesCollectedInCurrency(string currency, uint amount) public payable;

    function updateTokensReceivedFromDistributionFees(uint amountOfTokens) public;
}

contract ITwoKeyCampaignLogicHandler {
    function canContractorWithdrawRemainingRewardsInventory() public view returns (bool);
    function reduceTotalRaisedFundsAfterConversionRejected(uint amountToReduce) public;
}

contract ITwoKeyCampaignValidator {
    function isCampaignValidated(address campaign) public view returns (bool);
    function validateAcquisitionCampaign(address campaign, string nonSingletonHash) public;
    function validateDonationCampaign(address campaign, address donationConversionHandler, address donationLogicHandler, string nonSingletonHash) public;
    function validateCPCCampaign(address campaign, string nonSingletonHash) public;
}

contract ITwoKeyDeepFreezeTokenPool {
    function updateReceivedTokensForSuccessfulConversions(
        uint amount,
        address campaignAddress
    )
    public;
}

contract ITwoKeyDonationConversionHandler {
    function supportForCreateConversion(
        address _converterAddress,
        uint _conversionAmount,
        uint _maxReferralRewardETHWei,
        bool _isKYCRequired,
        uint conversionAmountCampaignCurrency
    )
    public
    returns (uint);

    function executeConversion(
        uint _conversionId
    )
    public;

    function getAmountConverterSpent(
        address converter
    )
    public
    view
    returns (uint);

    function getAmountOfDonationTokensConverterReceived(
        address converter
    )
    public
    view
    returns (uint);

    function getStateForConverter(
        address _converter
    )
    external
    view
    returns (bytes32);

    function setExpiryConversionInHours(
        uint _expiryConversionInHours
    )
    public;

}

contract ITwoKeyDonationLogicHandler {
    function getReferrers(address customer) public view returns (address[]);

    function updateRefchainRewards(
        address _converter,
        uint _conversionId,
        uint totalBounty2keys
    )
    public;

    function getReferrerPlasmaTotalEarnings(address _referrer) public view returns (uint);
    function checkAllRequirementsForConversionAndTotalRaised(address converter, uint conversionAmount, uint debtPaid) external returns (bool,uint);
}

contract ITwoKeyFeeManager {
    function payDebtWhenConvertingOrWithdrawingProceeds(address _plasmaAddress, uint _debtPaying) public payable;
    function getDebtForUser(address _userPlasma) public view returns (uint);
    function payDebtWithDAI(address _plasmaAddress, uint _totalDebt, uint _debtPaid) public;
    function payDebtWith2Key(address _beneficiaryPublic, address _plasmaAddress, uint _amountOf2keyForRewards) public;
    function payDebtWith2KeyV2(
        address _beneficiaryPublic,
        address _plasmaAddress,
        uint _amountOf2keyForRewards,
        address _twoKeyEconomy,
        address _twoKeyAdmin
    ) public;
    function setRegistrationFeeForUser(address _plasmaAddress, uint _registrationFee) public;
    function addDebtForUser(address _plasmaAddress, uint _debtAmount, string _debtType) public;
    function withdrawEtherCollected() public returns (uint);
    function withdraw2KEYCollected() public returns (uint);
    function withdrawDAICollected(address _dai) public returns (uint);
}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

contract ITwoKeyReg {
    function addTwoKeyEventSource(address _twoKeyEventSource) public;
    function changeTwoKeyEventSource(address _twoKeyEventSource) public;
    function addWhereContractor(address _userAddress, address _contractAddress) public;
    function addWhereModerator(address _userAddress, address _contractAddress) public;
    function addWhereReferrer(address _userAddress, address _contractAddress) public;
    function addWhereConverter(address _userAddress, address _contractAddress) public;
    function getContractsWhereUserIsContractor(address _userAddress) public view returns (address[]);
    function getContractsWhereUserIsModerator(address _userAddress) public view returns (address[]);
    function getContractsWhereUserIsRefferer(address _userAddress) public view returns (address[]);
    function getContractsWhereUserIsConverter(address _userAddress) public view returns (address[]);
    function getTwoKeyEventSourceAddress() public view returns (address);
    function addName(string _name, address _sender, string _fullName, string _email, bytes signature) public;
    function addNameByUser(string _name) public;
    function getName2Owner(string _name) public view returns (address);
    function getOwner2Name(address _sender) public view returns (string);
    function getPlasmaToEthereum(address plasma) public view returns (address);
    function getEthereumToPlasma(address ethereum) public view returns (address);
    function checkIfTwoKeyMaintainerExists(address _maintainer) public view returns (bool);
    function getUserData(address _user) external view returns (bytes);
}

contract ITwoKeySingletoneRegistryFetchAddress {
    function getContractProxyAddress(string _contractName) public view returns (address);
    function getNonUpgradableContractAddress(string contractName) public view returns (address);
    function getLatestCampaignApprovedVersion(string campaignType) public view returns (string);
}

interface ITwoKeySingletonesRegistry {

    /**
    * @dev This event will be emitted every time a new proxy is created
    * @param proxy representing the address of the proxy created
    */
    event ProxyCreated(address proxy);


    /**
    * @dev This event will be emitted every time a new implementation is registered
    * @param version representing the version name of the registered implementation
    * @param implementation representing the address of the registered implementation
    * @param contractName is the name of the contract we added new version
    */
    event VersionAdded(string version, address implementation, string contractName);

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string _contractName, string version, address implementation) public;

    /**
    * @dev Tells the address of the implementation for a given version
    * @param _contractName is the name of the contract we're querying
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string _contractName, string version) public view returns (address);
}

contract IUpgradableExchange {

    function buyRate2key() public view returns (uint);
    function sellRate2key() public view returns (uint);

    function buyTokensWithERC20(
        uint amountOfTokens,
        address tokenAddress
    )
    public
    returns (uint,uint);

    function buyTokens(
        address _beneficiary
    )
    public
    payable
    returns (uint,uint);

    function buyStableCoinWith2key(
        uint _twoKeyUnits,
        address _beneficiary
    )
    public
    payable;

    function report2KEYWithdrawnFromNetwork(
        uint amountOfTokensWithdrawn
    )
    public;

    function getEth2DaiAverageExchangeRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint);

    function getContractId(
        address _contractAddress
    )
    public
    view
    returns (uint);

    function getEth2KeyAverageRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint);

    function returnLeftoverAfterRebalancing(
        uint amountOf2key
    )
    public;


    function getMore2KeyTokensForRebalancing(
        uint amountOf2KeyRequested
    )
    public
    view
    returns (uint);


    function releaseAllDAIFromContractToReserve()
    public;

    function setKyberReserveInterfaceContractAddress(
        address kyberReserveContractAddress
    )
    public;

    function setSpreadWei(
        uint newSpreadWei
    )
    public;

    function withdrawDAIAvailableToFill2KEYReserve(
        uint amountOfDAI
    )
    public
    returns (uint);

    function returnTokensBackToExchangeV1(
        uint amountOfTokensToReturn
    )
    public;


    function getMore2KeyTokensForRebalancingV1(
        uint amountOfTokensRequested
    )
    public;
}

contract ITwoKeyEventSourceStorage is IStructuredStorage {

}

library Call {
    function params0(address c, bytes _method) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
        // move pointer to free memory spot
            let ptr := mload(0x40)
        // put function sig at memory spot
            mstore(ptr,sig)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x04, // Inputs are 0 bytes long
            ptr,  //Store output over input
            0x20) //Outputs are 1 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }

    function params1(address c, bytes _method, uint _val) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
        // move pointer to free memory spot
            let ptr := mload(0x40)
        // put function sig at memory spot
            mstore(ptr,sig)
        // append argument after function sig
            mstore(add(ptr,0x04), _val)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x24, // Inputs are 0 bytes long
            ptr,  //Store output over input
            0x20) //Outputs are 1 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }

    function params2(address c, bytes _method, uint _val1, uint _val2) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
            // move pointer to free memory spot
            let ptr := mload(0x40)
            // put function sig at memory spot
            mstore(ptr,sig)
            // append argument after function sig
            mstore(add(ptr,0x04), _val1)
            mstore(add(ptr,0x24), _val2)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x44, // Inputs are 4 bytes for signature and 2 uint256
            ptr,  //Store output over input
            0x20) //Outputs are 1 uint long

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x20)) // Set storage pointer to new space
        }
    }

    function loadAddress(bytes sig, uint idx) public pure returns (address) {
        address influencer;
        idx += 20;
        assembly
        {
            influencer := mload(add(sig, idx))
        }
        return influencer;
    }

    function loadUint8(bytes sig, uint idx) public pure returns (uint8) {
        uint8 weight;
        idx += 1;
        assembly
        {
            weight := mload(add(sig, idx))
        }
        return weight;
    }


    function recoverHash(bytes32 hash, bytes sig, uint idx) public pure returns (address) {
        // same as recoverHash in utils/sign.js
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        require (sig.length >= 65+idx, 'bad signature length');
        idx += 32;
        bytes32 r;
        assembly
        {
            r := mload(add(sig, idx))
        }

        idx += 32;
        bytes32 s;
        assembly
        {
            s := mload(add(sig, idx))
        }

        idx += 1;
        uint8 v;
        assembly
        {
            v := mload(add(sig, idx))
        }
        if (v >= 32) { // handle case when signature was made with ethereum web3.eth.sign or getSign which is for signing ethereum transactions
            v -= 32;
            bytes memory prefix = "\x19Ethereum Signed Message:\n32"; // 32 is the number of bytes in the following hash
            hash = keccak256(abi.encodePacked(prefix, hash));
        }
        if (v <= 1) v += 27;
        require(v==27 || v==28,'bad sig v');
        //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol#L57
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, 'bad sig s');
        return ecrecover(hash, v, r, s);

    }

    function recoverSigMemory(bytes sig) private pure returns (address[], address[], uint8[], uint[], uint) {
        uint8 version = loadUint8(sig, 0);
        uint msg_len = (version == 1) ? 1+65+20 : 1+20+20;
        uint n_influencers = (sig.length-21) / (65+msg_len);
        uint8[] memory weights = new uint8[](n_influencers);
        address[] memory keys = new address[](n_influencers);
        if ((sig.length-21) % (65+msg_len) > 0) {
            n_influencers++;
        }
        address[] memory influencers = new address[](n_influencers);
        uint[] memory offsets = new uint[](n_influencers);

        return (influencers, keys, weights, offsets, msg_len);
    }

    function recoverSigParts(bytes sig, address last_address) private pure returns (address[], address[], uint8[], uint[]) {
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
        uint idx = 0;
        uint msg_len;
        uint8[] memory weights;
        address[] memory keys;
        address[] memory influencers;
        uint[] memory offsets;
        (influencers, keys, weights, offsets, msg_len) = recoverSigMemory(sig);
        idx += 1;  // skip version

        idx += 20; // skip old_address which should be read by the caller in order to get old_key
        uint count_influencers = 0;

        while (idx + 65 <= sig.length) {
            offsets[count_influencers] = idx;
            idx += 65;  // idx was increased by 65 for the signature at the begining which we will process later

            if (idx + msg_len <= sig.length) {  // its  a < and not a <= because we dont want this to be the final iteration for the converter
                weights[count_influencers] = loadUint8(sig, idx);
                require(weights[count_influencers] > 0,'weight not defined (1..255)');  // 255 are used to indicate default (equal part) behaviour
                idx++;


                if (msg_len == 41)  // 1+20+20 version 0
                {
                    influencers[count_influencers] = loadAddress(sig, idx);
                    idx += 20;
                    keys[count_influencers] = loadAddress(sig, idx);
                    idx += 20;
                } else if (msg_len == 86)  // 1+65+20 version 1
                {
                    keys[count_influencers] = loadAddress(sig, idx+65);
                    influencers[count_influencers] = recoverHash(
                        keccak256(
                            abi.encodePacked(
                                keccak256(abi.encodePacked("bytes binding to weight","bytes binding to public")),
                                keccak256(abi.encodePacked(weights[count_influencers],keys[count_influencers]))
                            )
                        ),sig,idx);
                    idx += 65;
                    idx += 20;
                }

            } else {
                // handle short signatures generated with free_take
                influencers[count_influencers] = last_address;
            }
            count_influencers++;
        }
        require(idx == sig.length,'illegal message size');

        return (influencers, keys, weights, offsets);
    }

    function recoverSig(bytes sig, address old_key, address last_address) public pure returns (address[], address[], uint8[]) {
        // validate sig AND
        // recover the information from the signature: influencers, public_link_keys, weights/cuts
        // influencers may have one more address than the keys and weights arrays
        //
        require(old_key != address(0),'no public link key');

        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        uint[] memory offsets;
        (influencers, keys, weights, offsets) = recoverSigParts(sig, last_address);

        // check if we received a valid signature
        for(uint i = 0; i < influencers.length; i++) {
            if (i < weights.length) {
                require (recoverHash(keccak256(abi.encodePacked(weights[i], keys[i], influencers[i])),sig,offsets[i]) == old_key, 'illegal signature');
                old_key = keys[i];
            } else {
                // signed message for the last step is the address of the converter
                require (recoverHash(keccak256(abi.encodePacked(influencers[i])),sig,offsets[i]) == old_key, 'illegal last signature');
            }
        }

        return (influencers, keys, weights);
    }
}

library IncentiveModels {
    using SafeMath for uint;
    /**
     * @notice Implementation of average incentive model, reward is splited equally per referrer
     * @param totalBounty is total reward for the influencers
     * @param numberOfInfluencers is how many influencers we're splitting reward between
     */
    function averageModelRewards(
        uint totalBounty,
        uint numberOfInfluencers
    ) internal pure returns (uint) {
        if(numberOfInfluencers > 0) {
            uint equalPart = totalBounty.div(numberOfInfluencers);
            return equalPart;
        }
        return 0;
    }

    /**
     * @notice Implementation similar to average incentive model, except direct referrer) - gets 3x as the others
     * @param totalBounty is total reward for the influencers
     * @param numberOfInfluencers is how many influencers we're splitting reward between
     * @return two values, first is reward per regular referrer, and second is reward for last referrer in the chain
     */
    function averageLast3xRewards(
        uint totalBounty,
        uint numberOfInfluencers
    ) internal pure returns (uint,uint) {
        if(numberOfInfluencers> 0) {
            uint rewardPerReferrer = totalBounty.div(numberOfInfluencers.add(2));
            uint rewardForLast = rewardPerReferrer.mul(3);
            return (rewardPerReferrer, rewardForLast);
        }
        return (0,0);
    }

    /**
     * @notice Function to return array of corresponding values with rewards in power law schema
     * @param totalBounty is totalReward
     * @param numberOfInfluencers is the total number of influencers
     * @return rewards in wei
     */
    function powerLawRewards(
        uint totalBounty,
        uint numberOfInfluencers,
        uint factor
    ) internal pure returns (uint[]) {
        uint[] memory rewards = new uint[](numberOfInfluencers);
        if(numberOfInfluencers > 0) {
            uint x = calculateX(totalBounty,numberOfInfluencers,factor);
            for(uint i=0; i<numberOfInfluencers;i++) {
                rewards[numberOfInfluencers.sub(i.add(1))] = x.div(factor**i);
            }
        }
        return rewards;
    }


    /**
     * @notice Function to calculate base for all rewards in power law model
     * @param sumWei is the total reward to be splited in Wei
     * @param numberOfElements is the number of referrers in the chain
     * @return wei value of base for the rewards in power law
     */
    function calculateX(
        uint sumWei,
        uint numberOfElements,
        uint factor
    ) private pure returns (uint) {
        uint a = 1;
        uint sumOfFactors = 1;
        for(uint i=1; i<numberOfElements; i++) {
            a = a.mul(factor);
            sumOfFactors = sumOfFactors.add(a);
        }
        return sumWei.mul(a).div(sumOfFactors);
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
  }
}

contract ITwoKeySingletonUtils {

    address public TWO_KEY_SINGLETON_REGISTRY;

    // Modifier to restrict method calls only to maintainers
    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    /**
     * @notice Function to get any singleton contract proxy address from TwoKeySingletonRegistry contract
     * @param contractName is the name of the contract we're looking for
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getContractProxyAddress(contractName);
    }

    function getNonUpgradableContractAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getNonUpgradableContractAddress(contractName);
    }
}

contract UpgradeabilityStorage {
    // Versions registry
    ITwoKeySingletonesRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

contract Upgradeable is UpgradeabilityStorage {
    /**
     * @dev Validates the caller is the versions registry.
     * @param sender representing the address deploying the initial behavior of the contract
     */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}

contract TwoKeyEventSource is Upgradeable, ITwoKeySingletonUtils {

    bool initialized;

    ITwoKeyEventSourceStorage public PROXY_STORAGE_CONTRACT;


    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
    string constant _twoKeyFactory = "TwoKeyFactory";
    string constant _twoKeyRegistry = "TwoKeyRegistry";
    string constant _twoKeyAdmin = "TwoKeyAdmin";
    string constant _twoKeyExchangeRateContract = "TwoKeyExchangeRateContract";
    string constant _twoKeyMaintainersRegistry = "TwoKeyMaintainersRegistry";
    string constant _deepFreezeTokenPool = "TwoKeyDeepFreezeTokenPool";

    /**
     * Modifier which will allow only completely verified and validated contracts to call some functions
     */
    modifier onlyAllowedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }

    /**
     * Modifier which will allow only TwoKeyCampaignValidator to make some calls
     */
    modifier onlyTwoKeyCampaignValidator {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(msg.sender == twoKeyCampaignValidator);
        _;
    }

    /**
     * @notice Function to set initial params in the contract
     * @param _twoKeySingletonesRegistry is the address of TWO_KEY_SINGLETON_REGISTRY contract
     * @param _proxyStorage is the address of proxy of storage contract
     */
    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyEventSourceStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * Events which will be emitted during use of system
     * All events are emitted from this contract
     * Every event is monitored in GraphQL
     */

    event Created(
        address _campaign,
        address _owner,
        address _moderator
    );

    event Joined(
        address _campaign,
        address _from,
        address _to
    );

    event Converted(
        address _campaign,
        address _converter,
        uint256 _amount
    );

    event ConvertedAcquisition(
        address _campaign,
        address _converterPlasma,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion,
        uint _conversionId
    );

    event ConvertedDonation(
        address _campaign,
        address _converterPlasma,
        uint _conversionAmount,
        uint _conversionId
    );

    event Rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    );

    event Cancelled(
        address _campaign,
        address _converter,
        uint256 _indexOrAmount
    );

    event Rejected(
        address _campaign,
        address _converter
    );

    event UpdatedPublicMetaHash(
        uint timestamp,
        string value
    );

    event UpdatedData(
        uint timestamp,
        uint value,
        string action
    );

    event ReceivedEther(
        address _sender,
        uint value
    );

    event AcquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    );

    event DonationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    );

    event CPCCampaignCreated(
        address proxyCPCCampaign,
        address contractor //Contractor public address
    );

    event PriceUpdated(
        bytes32 _currency,
        uint newRate,
        uint _timestamp,
        address _updater
    );

    event UserRegistered(
        string _handle,
        address _address
    );

    event Executed(
        address campaignAddress,
        address converterPlasmaAddress,
        uint conversionId,
        uint tokens
    );

    event TokenWithdrawnFromPurchasesHandler(
        address campaignAddress,
        uint conversionID,
        uint tokensAmountWithdrawn
    );

    event Debt (
        address plasmaAddress,
        uint weiAmount,
        bool addition, //If true means debt increasing otherwise it means that event emitted when user paid part of the debt
        string currency
    );

    event ReceivedTokensAsModerator(
        address campaignAddress,
        uint amountOfTokens
    );

    event ReceivedTokensDeepFreezeTokenPool(
        address campaignAddress,
        uint amountOfTokens
    );

    event HandleChanged(
        address userPlasmaAddress,
        string newHandle
    );

    event DaiReleased(
        address contractSenderAddress,
        uint amountOfDAI
    );

    event RebalancedRatesEvent (
        uint priceAtBeginning,
        uint priceAtRebalancingTime,
        uint ratio,
        uint amountOfTokensTransferedInAction,
        string actionPerformedWithUpgradableExchange
    );

    event EndedBudgetCampaign (
        address campaignPlasmaAddress,
        uint contractorLeftover,
        uint moderatorEarningsDistributed
    );

    event RebalancedRewards(
        uint cycleId,
        uint amountOfTokens,
        string action
    );

    event UserWithdrawnNetworkEarnings(
        address user,
        uint amountOfTokens
    );

    /**
     * @notice Function to emit created event every time campaign is created
     * @param _campaign is the address of the deployed campaign
     * @param _owner is the contractor address of the campaign
     * @param _moderator is the address of the moderator in campaign
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function created(
        address _campaign,
        address _owner,
        address _moderator
    )
    external
    onlyTwoKeyCampaignValidator
    {
        emit Created(_campaign, _owner, _moderator);
    }

    /**
     * @notice Function to emit created event every time someone has joined to campaign
     * @param _campaign is the address of the deployed campaign
     * @param _from is the address of the referrer
     * @param _to is the address of person who has joined
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function joined(
        address _campaign,
        address _from,
        address _to
    )
    external
    onlyAllowedContracts
    {
        emit Joined(_campaign, _from, _to);
    }

    /**
     * @notice Function to emit converted event
     * @param _campaign is the address of main campaign contract
     * @param _converter is the address of converter during the conversion
     * @param _conversionAmount is conversion amount
     */
    function converted(
        address _campaign,
        address _converter,
        uint256 _conversionAmount
    )
    external
    onlyAllowedContracts
    {
        emit Converted(_campaign, _converter, _conversionAmount);
    }

    function rejected(
        address _campaign,
        address _converter
    )
    external
    onlyAllowedContracts
    {
        emit Rejected(_campaign, _converter);
    }


    /**
     * @notice Function to emit event every time conversion gets executed
     * @param _campaignAddress is the main campaign contract address
     * @param _converterPlasmaAddress is the address of converter plasma
     * @param _conversionId is the ID of conversion, unique per campaign
     */
    function executed(
        address _campaignAddress,
        address _converterPlasmaAddress,
        uint _conversionId,
        uint tokens
    )
    external
    onlyAllowedContracts
    {
        emit Executed(_campaignAddress, _converterPlasmaAddress, _conversionId, tokens);
    }


    /**
     * @notice Function to emit created event every time conversion happened under AcquisitionCampaign
     * @param _campaign is the address of the deployed campaign
     * @param _converterPlasma is the converter address
     * @param _baseTokens is the amount of tokens bought
     * @param _bonusTokens is the amount of bonus tokens received
     * @param _conversionAmount is the amount of conversion
     * @param _isFiatConversion is flag representing if conversion is either FIAT or ETHER
     * @param _conversionId is the id of conversion
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function convertedAcquisition(
        address _campaign,
        address _converterPlasma,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion,
        uint _conversionId
    )
    external
    onlyAllowedContracts
    {
        emit ConvertedAcquisition(
            _campaign,
            _converterPlasma,
            _baseTokens,
            _bonusTokens,
            _conversionAmount,
            _isFiatConversion,
            _conversionId
        );
    }



    /**
     * @notice Function to emit created event every time conversion happened under DonationCampaign
     * @param _campaign is the address of main campaign contract
     * @param _converterPlasma is the address of the converter
     * @param _conversionAmount is the amount of conversion
     * @param _conversionId is the id of conversion
     */
    function convertedDonation(
        address _campaign,
        address _converterPlasma,
        uint256 _conversionAmount,
        uint256 _conversionId
    )
    external
    onlyAllowedContracts
    {
        emit ConvertedDonation(
            _campaign,
            _converterPlasma,
            _conversionAmount,
            _conversionId
        );
    }

    /**
     * @notice Function to emit created event every time bounty is distributed between influencers
     * @param _campaign is the address of the deployed campaign
     * @param _to is the reward receiver
     * @param _amount is the reward amount
     */
    function rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    )
    external
    onlyAllowedContracts
    {
        emit Rewarded(_campaign, _to, _amount);
    }

    /**
     * @notice Function to emit created event every time campaign is cancelled
     * @param _campaign is the address of the cancelled campaign
     * @param _converter is the address of the converter
     * @param _indexOrAmount is the amount of campaign
     */
    function cancelled(
        address  _campaign,
        address _converter,
        uint256 _indexOrAmount
    )
    external
    onlyAllowedContracts
    {
        emit Cancelled(_campaign, _converter, _indexOrAmount);
    }

    /**
     * @notice Function to emit event every time someone starts new Acquisition campaign
     * @param proxyLogicHandler is the address of TwoKeyAcquisitionLogicHandler proxy deployed by TwoKeyFactory
     * @param proxyConversionHandler is the address of TwoKeyConversionHandler proxy deployed by TwoKeyFactory
     * @param proxyAcquisitionCampaign is the address of TwoKeyAcquisitionCampaign proxy deployed by TwoKeyFactory
     * @param proxyPurchasesHandler is the address of TwoKeyPurchasesHandler proxy deployed by TwoKeyFactory
     */
    function acquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyFactory));
        emit AcquisitionCampaignCreated(
            proxyLogicHandler,
            proxyConversionHandler,
            proxyAcquisitionCampaign,
            proxyPurchasesHandler,
            contractor
        );
    }

    /**
     * @notice Function to emit event every time someone starts new Donation campaign
     * @param proxyDonationCampaign is the address of TwoKeyDonationCampaign proxy deployed by TwoKeyFactory
     * @param proxyDonationConversionHandler is the address of TwoKeyDonationConversionHandler proxy deployed by TwoKeyFactory
     * @param proxyDonationLogicHandler is the address of TwoKeyDonationLogicHandler proxy deployed by TwoKeyFactory
     */
    function donationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyFactory));
        emit DonationCampaignCreated(
            proxyDonationCampaign,
            proxyDonationConversionHandler,
            proxyDonationLogicHandler,
            contractor
        );
    }


    /**
     * @notice Function to emit event every time someone starts new CPC campaign
     * @param proxyCPC is the proxy address of CPC campaign
     * @param contractor is the PUBLIC address of campaign contractor
     */
    function cpcCampaignCreated(
        address proxyCPC,
        address contractor
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyFactory));
        emit CPCCampaignCreated(
            proxyCPC,
            contractor
        );
    }

    /**
     * @notice Function which will emit event PriceUpdated every time that happens under TwoKeyExchangeRateContract
     * @param _currency is the hexed string of currency name
     * @param _newRate is the new rate
     * @param _timestamp is the time of updating
     * @param _updater is the maintainer address which performed this call
     */
    function priceUpdated(
        bytes32 _currency,
        uint _newRate,
        uint _timestamp,
        address _updater
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyExchangeRateContract));
        emit PriceUpdated(_currency, _newRate, _timestamp, _updater);
    }

    /**
     * @notice Function to emit event every time user is registered
     * @param _handle is the handle of the user
     * @param _address is the address of the user
     */
    function userRegistered(
        string _handle,
        address _address,
        uint _registrationFee
    )
    external
    {
        require(isAddressMaintainer(msg.sender) == true);
        ITwoKeyFeeManager(getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager")).setRegistrationFeeForUser(_address, _registrationFee);
        emit UserRegistered(_handle, _address);
        emit Debt(_address, _registrationFee, true, "ETH");
    }

    function addAdditionalDebtForUser(
        address _plasmaAddress,
        uint _debtAmount,
        string _debtType
    )
    public
    {
        require(isAddressMaintainer(msg.sender) == true);
        ITwoKeyFeeManager(getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager")).addDebtForUser(_plasmaAddress, _debtAmount, _debtType);
        emit Debt(_plasmaAddress, _debtAmount, true, "ETH");
    }

    /**
     * @notice Function which will emit every time some debt is increased or paid
     * @param _plasmaAddress is the address of the user we are increasing/decreasing debt for
     * @param _amount is the amount of ETH he paid/increased
     * @param _isAddition is stating either debt increased or paid
     */
    function emitDebtEvent(
        address _plasmaAddress,
        uint _amount,
        bool _isAddition,
        string _currency
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager"));
        emit Debt(
            _plasmaAddress,
            _amount,
            _isAddition,
            _currency
        );
    }

    /**
     * @notice Function which will be called by TwoKeyAdmin every time it receives 2KEY tokens
     * as a moderator on TwoKeyCampaigns
     * @param _campaignAddress is the address of the campaign sending tokens
     * @param _amountOfTokens is the amount of tokens sent
     */
    function emitReceivedTokensAsModerator(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin));
        emit ReceivedTokensAsModerator(
            _campaignAddress,
            _amountOfTokens
        );
    }

    /**
     * @notice Function which will be called by TwoKeyDeepFreezeTokenPool every time it receives 2KEY tokens
     * from moderator rewards on the conversion event
     * @param _campaignAddress is the address of the campaign sending tokens
     * @param _amountOfTokens is the amount of tokens sent
     */
    function emitReceivedTokensToDeepFreezeTokenPool(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_deepFreezeTokenPool));
        emit ReceivedTokensDeepFreezeTokenPool(
            _campaignAddress,
            _amountOfTokens
        );
    }


    /**
     * @notice Function which will emit an event every time somebody performs
     * withdraw of bought tokens in AcquisitionCampaign contracts
     * @param _campaignAddress is the address of main campaign contract
     * @param _conversionID is the unique ID of conversion inside one campaign
     * @param _tokensAmountWithdrawn is the amount of tokens user withdrawn
     */
    function tokensWithdrawnFromPurchasesHandler(
        address _campaignAddress,
        uint _conversionID,
        uint _tokensAmountWithdrawn
    )
    external
    onlyAllowedContracts
    {
        emit TokenWithdrawnFromPurchasesHandler(_campaignAddress, _conversionID, _tokensAmountWithdrawn);
    }


    function emitRebalancedRatesEvent(
        uint priceAtBeginning,
        uint priceAtRebalancingTime,
        uint ratio,
        uint amountOfTokensTransferedInAction,
        string actionPerformedWithUpgradableExchange
    )
    external
    onlyAllowedContracts
    {
        emit RebalancedRatesEvent(
            priceAtBeginning,
            priceAtRebalancingTime,
            ratio,
            amountOfTokensTransferedInAction,
            actionPerformedWithUpgradableExchange
        );
    }

    function emitHandleChangedEvent(
        address _userPlasmaAddress,
        string _newHandle
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));

        emit HandleChanged(
            _userPlasmaAddress,
            _newHandle
        );
    }


    /**
     * @notice          Function to emit an event whenever DAI is released as an income
     *
     * @param           _campaignContractAddress is campaign contract address
     * @param           _amountOfDAI is the amount of DAI being released
     */
    function emitDAIReleasedAsIncome(
        address _campaignContractAddress,
        uint _amountOfDAI
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange"));

        emit DaiReleased(
            _campaignContractAddress,
            _amountOfDAI
        );
    }

    function emitEndedBudgetCampaign(
        address campaignPlasmaAddress,
        uint contractorLeftover,
        uint moderatorEarningsDistributed
    )
    public
    {
        require (msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));

        emit EndedBudgetCampaign(
            campaignPlasmaAddress,
            contractorLeftover,
            moderatorEarningsDistributed
        );
    }


    function emitRebalancedRewards(
        uint cycleId,
        uint difference,
        string action
    )
    public
    {
        require (msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));

        emit RebalancedRewards(
            cycleId,
            difference,
            action
        );
    }


    /**
     * @notice          Function which will emit event that user have withdrawn network earnings
     * @param           user is the address of the user
     * @param           amountOfTokens is the amount of tokens user withdrawn as network earnings
     */
    function emitUserWithdrawnNetworkEarnings(
        address user,
        uint amountOfTokens
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyParticipationMiningPool"));

        emit UserWithdrawnNetworkEarnings(
            user,
            amountOfTokens
        );
    }


    /**
     * @notice Function to check adequate plasma address for submitted eth address
     * @param me is the ethereum address we request corresponding plasma address for
     */
    function plasmaOf(
        address me
    )
    public
    view
    returns (address)
    {
        address twoKeyRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyRegistry);
        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(me);
        if (plasma != address(0)) {
            return plasma;
        }
        return me;
    }

    /**
     * @notice Function to determine ethereum address of plasma address
     * @param me is the plasma address of the user
     * @return ethereum address
     */
    function ethereumOf(
        address me
    )
    public
    view
    returns (address)
    {
        address twoKeyRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyRegistry);
        address ethereum = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(me);
        if (ethereum != address(0)) {
            return ethereum;
        }
        return me;
    }

    /**
     * @notice Address to check if an address is maintainer in TwoKeyMaintainersRegistry
     * @param _maintainer is the address we're checking this for
     */
    function isAddressMaintainer(
        address _maintainer
    )
    public
    view
    returns (bool)
    {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
        bool _isMaintainer = ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(_maintainer);
        return _isMaintainer;
    }

    /**
     * @notice In default TwoKeyAdmin will be moderator and his fee percentage per conversion is predefined
     */
    function getTwoKeyDefaultIntegratorFeeFromAdmin()
    public
    view
    returns (uint)
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        uint integratorFeePercentage = ITwoKeyAdmin(twoKeyAdmin).getDefaultIntegratorFeePercent();
        return integratorFeePercentage;
    }

    /**
     * @notice Function to get default network tax percentage
     */
    function getTwoKeyDefaultNetworkTaxPercent()
    public
    view
    returns (uint)
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        uint networkTaxPercent = ITwoKeyAdmin(twoKeyAdmin).getDefaultNetworkTaxPercent();
        return networkTaxPercent;
    }
}

contract UpgradeabilityCampaignStorage {

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

contract UpgradeableCampaign is UpgradeabilityCampaignStorage {

}

contract TwoKeyDonationCampaign is UpgradeableCampaign, TwoKeyCampaignIncentiveModels, TwoKeyCampaign {

    bool initialized;

    bool acceptsFiat; // Will determine if fiat conversion can be created or not


    function setInitialParamsDonationCampaign(
        address _contractor,
        address _moderator,
        address _twoKeySingletonRegistry,
        address _twoKeyDonationConversionHandler,
        address _twoKeyDonationLogicHandler,
        uint [] numberValues,
        bool [] booleanValues
    )
    public
    {
        require(initialized == false);
        require(numberValues[0] <= 100*(10**18)); //Require that max referral reward percent is less than 100%
        contractor = _contractor;
        moderator = _moderator;

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        twoKeyEventSource = TwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"));
                twoKeyEconomy = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
                    .getNonUpgradableContractAddress("TwoKeyEconomy");
        totalSupply_ = 1000000;

        maxReferralRewardPercent = numberValues[0];
        conversionQuota = numberValues[6];

        conversionHandler = _twoKeyDonationConversionHandler;
        logicHandler = _twoKeyDonationLogicHandler;


        mustConvertToReferr = booleanValues[0];
        isKYCRequired = booleanValues[1];
        acceptsFiat = booleanValues[2];


        ownerPlasma = twoKeyEventSource.plasmaOf(_contractor);
        received_from[ownerPlasma] = ownerPlasma;
        balances[ownerPlasma] = totalSupply_;

        //Because of stack depth
        ITwoKeyDonationConversionHandler(conversionHandler).setExpiryConversionInHours(numberValues[10]);

        initialized = true;
    }


    /**
     * @notice Option to update contractor proceeds
     * @dev can be called only from TwoKeyConversionHandler contract
     * @param value it the value we'd like to add to total contractor proceeds and contractor balance
     */
    function updateContractorProceeds(
        uint value
    )
    public
    {
        require(msg.sender == conversionHandler);
        contractorTotalProceeds = contractorTotalProceeds.add(value);
        contractorBalance = contractorBalance.add(value);
    }


    /**
     * @notice Function where converter can convert
     * @dev payable function
     */
    function convert(
        bytes signature
    )
    public
    payable
    {
        bool canConvert;
        uint conversionAmountCampaignCurrency;

        uint conversionAmount;
        uint debtPaid;
        (conversionAmount,debtPaid) = payFeesForUser(msg.sender, msg.value);

        (canConvert, conversionAmountCampaignCurrency) = ITwoKeyDonationLogicHandler(logicHandler).checkAllRequirementsForConversionAndTotalRaised(
            msg.sender,
            conversionAmount,
            debtPaid
        );

        require(canConvert == true);

        address _converterPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        uint numberOfInfluencers = distributeArcsIfNecessary(msg.sender, signature);
        createConversion(conversionAmount, msg.sender, conversionAmountCampaignCurrency, numberOfInfluencers);
    }

    /*
     * @notice Function which is executed to create conversion
     * @param conversionAmountETHWeiOrFiat is the amount of the ether sent to the contract
     * @param converterAddress is the sender of eth to the contract
     */
    function createConversion(
        uint conversionAmountEthWEI,
        address converterAddress,
        uint conversionAmountCampaignCurrency,
        uint numberOfInfluencers
    )
    private
    {
        uint maxReferralRewardFiatOrETHWei = calculateInfluencersFee(conversionAmountEthWEI, numberOfInfluencers);

        uint conversionId = ITwoKeyDonationConversionHandler(conversionHandler).supportForCreateConversion(
            converterAddress,
            conversionAmountEthWEI,
            maxReferralRewardFiatOrETHWei,
            isKYCRequired,
            conversionAmountCampaignCurrency
        );
        //If KYC is not required conversion is automatically executed
        if(isKYCRequired == false) {
            ITwoKeyDonationConversionHandler(conversionHandler).executeConversion(conversionId);
        }
    }

    /**
      * @notice Function to delegate call to logic handler and update data, and buy tokens
      * @param _maxReferralRewardETHWei total reward in ether wei
      * @param _converter is the converter address
      * @param _conversionId is the ID of conversion
      */
    function buyTokensAndDistributeReferrerRewards(
        uint256 _maxReferralRewardETHWei,
        address _converter,
        uint _conversionId
    )
    public
    returns (uint)
    {
        require(msg.sender == conversionHandler);
        //Fiat rewards = fiatamount * moderatorPercentage / 100  / 0.095
        uint totalBounty2keys = 0;
        if(_maxReferralRewardETHWei > 0) {
            //Buy tokens from upgradable exchange
            (totalBounty2keys,) = buyTokensFromUpgradableExchange(_maxReferralRewardETHWei, address(this));
        }
        //Handle refchain rewards
        ITwoKeyDonationLogicHandler(logicHandler).updateRefchainRewards(
            _converter,
            _conversionId,
            totalBounty2keys);

        reservedAmount2keyForRewards = reservedAmount2keyForRewards.add(totalBounty2keys);
        return totalBounty2keys;
    }


    /**
     * @notice Function which acts like getter for all cuts in array
     * @param last_influencer is the last influencer
     * @return array of integers containing cuts respectively
     */
    function getReferrerCuts(
        address last_influencer
    )
    public
    view
    returns (uint256[])
    {
        address[] memory influencers = ITwoKeyDonationLogicHandler(logicHandler).getReferrers(last_influencer);
        uint256[] memory cuts = new uint256[](influencers.length + 1);

        uint numberOfInfluencers = influencers.length;
        for (uint i = 0; i < numberOfInfluencers; i++) {
            address influencer = influencers[i];
            cuts[i] = getReferrerCut(influencer);
        }
        cuts[influencers.length] = getReferrerCut(last_influencer);
        return cuts;
    }


    /**
     * @param _referrer we want to check earnings for
     */
    function getReferrerBalance(address _referrer) public view returns (uint) {
        return referrerPlasma2Balances2key[twoKeyEventSource.plasmaOf(_referrer)];
    }


    /**
     * @notice Contractor can withdraw funds only if criteria is satisfied
     */
    function withdrawContractor() public onlyContractor {
        withdrawContractorInternal();
    }

    /**
     * @notice Function to get reserved amount of rewards
     */
    function getReservedAmount2keyForRewards() public view returns (uint) {
        return reservedAmount2keyForRewards;
    }

    function referrerWithdraw(
        address _address,
        bool _withdrawAsStable
    )
    public
    {
        referrerWithdrawInternal(_address, _withdrawAsStable);
    }


}

