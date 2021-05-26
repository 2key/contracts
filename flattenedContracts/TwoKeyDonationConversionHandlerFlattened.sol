pragma solidity ^0.4.13;

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _ocwner, address _spender) public view returns (uint256);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

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

contract TwoKeyCampaignConversionHandler is TwoKeyConversionStates, TwoKeyConverterStates {

    using SafeMath for uint256;

    uint expiryConversionInHours; // How long converter can be pending before he can cancel his conversion

    event ConversionCreated(uint conversionId);

    bool isCampaignInitialized;
    uint numberOfConversions;


    /**
     * This array will represent counter values where position will be index (which counter) and value will be actual counter value
     * counters[0] = PENDING_CONVERSIONS
     * counters[1] = APPROVED_CONVERSIONS
     * counters[2] = REJECTED_CONVERSIONS
     * counters[3] = EXECUTED_CONVERSIONS
     * counters[4] = CANCELLED_CONVERSIONS
     * counters[5] = UNIQUE_CONVERTERS
     * counters[6] = RAISED_FUNDS_ETH_WEI
     * counters[7] = TOKENS_SOLD
     * counters[8] = TOTAL_BOUNTY
     * counters[9] = RAISED_FUNDS_FIAT_WEI
     * counters[10] = CAMPAIGN_RAISED_BY_NOW_IN_CAMPAIGN_CURRENCY
     */
    uint [] counters;

    address contractor;
    address twoKeyEventSource;
    address twoKeyBaseReputationRegistry;
    address twoKeySingletonRegistry;


    mapping(address => uint256) amountConverterSpentEthWEI; // Amount converter put to the contract in Ether
    mapping(bytes32 => address[]) stateToConverter; //State to all converters in that state
    mapping(address => uint[]) converterToHisConversions;
    mapping(address => ConverterState) converterToState; //Converter to his state
    mapping(address => uint256) public converterToPositionIndex;
    mapping(address => bool) isConverterAnonymous;
    mapping(address => bool) doesConverterHaveExecutedConversions;
    mapping(uint => uint) conversionToCampaignCurrencyAmountAtTimeOfCreation;

    modifier onlyContractorOrMaintainer {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        require(msg.sender == contractor || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    modifier onlyContractor {
        require(msg.sender == contractor);
        _;
    }


    // Internal function to fetch address from TwoKeySingletonRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry)
        .getContractProxyAddress(contractName);
    }

    /**
     * given the total payout, calculates the moderator fee
     * @param  _conversionAmountETHWei total payout for escrow
     * @return moderator fee
     */
    function calculateModeratorFee(
        uint256 _conversionAmountETHWei
    )
    internal
    view
    returns (uint256)
    {
        uint256 fee = _conversionAmountETHWei.mul(ITwoKeyEventSource(twoKeyEventSource).getTwoKeyDefaultIntegratorFeeFromAdmin()).div(100);
        return fee;
    }


    function getAllConvertersPerState(
        bytes32 state
    )
    public
    view
    returns (address[])
    {
        return stateToConverter[state];
    }

    /// @notice Function where we can change state of converter to Approved
    /// @dev Converter can only be approved if his previous state is pending or rejected
    /// @param _converter is the address of converter
    function moveFromPendingOrRejectedToApprovedState(
        address _converter
    )
    internal
    {
        bytes32 destination = bytes32("APPROVED");
        moveFromStateAToStateB(_converter, destination);
        converterToState[_converter] = ConverterState.APPROVED;
    }


    /// @notice Function where we're going to move state of conversion from pending to rejected
    /// @dev private function, will be executed in another one
    /// @param _converter is the address of converter
    function moveFromPendingToRejectedState(
        address _converter
    )
    internal
    {
        bytes32 destination = bytes32("REJECTED");
        moveFromStateAToStateB(_converter, destination);
        converterToState[_converter] = ConverterState.REJECTED;
    }

    /// @notice Function to move converter address from stateA to stateB
    /// @param _converter is the address of converter
    /// @param destinationState is the state we'd like to move converter to
    function moveFromStateAToStateB(
        address _converter,
        bytes32 destinationState
    )
    internal
    {
        ConverterState state = converterToState[_converter];
        bytes32 key = convertConverterStateToBytes(state);
        address[] memory current = stateToConverter[key];

        uint index = converterToPositionIndex[_converter]; // Get converter index position in array
        if(current[index] == _converter) {
            // Add converter to new array
            stateToConverter[destinationState].push(_converter);
            // Set new position in the new array
            converterToPositionIndex[_converter] = stateToConverter[destinationState].length - 1;
            // Get the last converter from the array because we're moving him to deleted place and with that action
            // His new index will be the one of the removed converter
            address lastConverterInArray = current[current.length-1];
            // Reduce size of current array
            current[index] = lastConverterInArray;
            // Set index to be the position of the last converter in the array
            converterToPositionIndex[lastConverterInArray] = index;
            // Delete last element in current array
            delete current[current.length-1];
            // Save current array
            stateToConverter[key] = current;
            // Change length of the mapping array
            stateToConverter[key].length = stateToConverter[key].length.sub(1);
        }
    }

    /// @notice Function where we are approving converter
    /// @dev only maintainer or contractor can call this method
    /// @param _converter is the address of converter
    function approveConverter(
        address _converter
    )
    public
    onlyContractorOrMaintainer
    {
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);
        moveFromPendingOrRejectedToApprovedState(_converter);
    }

    function rejectConverterInternal(
        address _converter
    )
    internal
    {
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);
        moveFromPendingToRejectedState(_converter);
    }

    function handleConverterState(
        address _converterAddress,
        bool isKYCRequired
    )
    internal
    {
        //If KYC is required, basic funnel executes and we require that converter is not previously rejected
        if(isKYCRequired == true) {
            require(converterToState[_converterAddress] != ConverterState.REJECTED); // If converter is rejected then can't create conversion
            // Checking the state for converter, if this is his 1st time, he goes initially to PENDING_APPROVAL
            if(converterToState[_converterAddress] == ConverterState.NOT_EXISTING) {
                converterToState[_converterAddress] = ConverterState.PENDING_APPROVAL;
                stateToConverter[bytes32("PENDING_APPROVAL")].push(_converterAddress);
                converterToPositionIndex[_converterAddress] = stateToConverter[bytes32("PENDING_APPROVAL")].length-1;
            }
        } else {
            //If KYC is not required converter is automatically approved
            if(converterToState[_converterAddress] == ConverterState.NOT_EXISTING) {
                converterToState[_converterAddress] = ConverterState.APPROVED;
                stateToConverter[bytes32("APPROVED")].push(_converterAddress);
                converterToPositionIndex[_converterAddress] = stateToConverter[bytes32("APPROVED")].length-1;
            }
        }
    }

    /**
     * @notice Function to get all conversion ids for the converter
     * @param _converter is the address of the converter
     * @return array of conversion ids
     * @dev can only be called by converter itself or maintainer/contractor
     */
    function getConverterConversionIds(
        address _converter
    )
    public
    view
    returns (uint[])
    {
        return converterToHisConversions[_converter];
    }


    function getLastConverterConversionId(
        address _converter
    )
    public
    view
    returns (uint)
    {
        return converterToHisConversions[_converter][converterToHisConversions[_converter].length - 1];
    }

    /**
     * @notice Function to get number of conversions
     * @dev Can only be called by contractor or maintainer
     */
    function getNumberOfConversions()
    external
    view
    returns (uint)
    {
        return numberOfConversions;
    }

    /**
     * @notice Function to get converter state
     * @param _converter is the address of the requested converter
     * @return hexed string of the state
     */
    function getStateForConverter(
        address _converter
    )
    external
    view
    returns (bytes32)
    {
        return convertConverterStateToBytes(converterToState[_converter]);
    }

    /**
     * @notice Get's number of converters per type, and returns tuple, as well as total raised funds
     */
    function getCampaignSummary()
    public
    view
    returns (uint,uint,uint,uint[])
    {
        bytes32 pending = convertConverterStateToBytes(ConverterState.PENDING_APPROVAL);
        bytes32 approved = convertConverterStateToBytes(ConverterState.APPROVED);
        bytes32 rejected = convertConverterStateToBytes(ConverterState.REJECTED);

        uint numberOfPending = stateToConverter[pending].length;
        uint numberOfApproved = stateToConverter[approved].length;
        uint numberOfRejected = stateToConverter[rejected].length;

        return (
            numberOfPending,
            numberOfApproved,
            numberOfRejected,
            counters
        );
    }



}

contract InvoiceToken is ERC20 {

    using SafeMath for uint256;

    uint256 internal totalSupply_ = 10000000000000000000000000000;
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    address public owner;


    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) internal balances;


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    constructor(string _name, string _symbol, address _tokensOwner) public {
        owner = _tokensOwner;
        name = _name;
        symbol = _symbol;
        balances[_tokensOwner] = totalSupply_;
        emit Transfer(address(this), _tokensOwner, totalSupply_);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        revert();
    }

    /**
     * @dev approve is not supported regarding the specs
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        revert();
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public onlyOwner returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
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

contract ITwoKeyBaseReputationRegistry {
    function updateOnConversionExecutedEvent(address converter, address contractor, address campaign) public;
    function updateOnConversionRejectedEvent(address converter, address contractor, address campaign) public;
}

contract ITwoKeyCampaignLogicHandler {
    function canContractorWithdrawRemainingRewardsInventory() public view returns (bool);
    function reduceTotalRaisedFundsAfterConversionRejected(uint amountToReduce) public;
}

contract ITwoKeyDonationCampaign {
    address public logicHandler;
    function buyTokensForModeratorRewards(
        uint moderatorFee
    )
    public;

    function buyTokensAndDistributeReferrerRewards(
        uint256 _maxReferralRewardETHWei,
        address _converter,
        uint _conversionId
    )
    public
    returns (uint);

    function updateReferrerPlasmaBalance(address _influencer, uint _balance) public;
    function updateContractorProceeds(uint value) public;
    function sendBackEthWhenConversionCancelledOrRejected(address _cancelledConverter, uint _conversionAmount) public;
}

contract ITwoKeyEventSource {

    function ethereumOf(address me) public view returns (address);
    function plasmaOf(address me) public view returns (address);
    function isAddressMaintainer(address _maintainer) public view returns (bool);
    function getTwoKeyDefaultIntegratorFeeFromAdmin() public view returns (uint);
    function joined(address _campaign, address _from, address _to) external;
    function rejected(address _campaign, address _converter) external;

    function convertedAcquisition(
        address _campaign,
        address _converterPlasma,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion,
        uint _conversionId
    )
    external;

    function getTwoKeyDefaultNetworkTaxPercent()
    public
    view
    returns (uint);

    function convertedDonation(
        address _campaign,
        address _converterPlasma,
        uint256 _conversionAmount,
        uint256 _conversionId
    )
    external;

    function executed(
        address _campaignAddress,
        address _converterPlasmaAddress,
        uint _conversionId,
        uint tokens
    )
    external;

    function tokensWithdrawnFromPurchasesHandler(
        address campaignAddress,
        uint _conversionID,
        uint _tokensAmountWithdrawn
    )
    external;

    function emitDebtEvent(
        address _plasmaAddress,
        uint _amount,
        bool _isAddition,
        string _currency
    )
    external;

    function emitReceivedTokensToDeepFreezeTokenPool(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public;

    function emitReceivedTokensAsModerator(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public;

    function emitDAIReleasedAsIncome(
        address _campaignContractAddress,
        uint _amountOfDAI
    )
    public;

    function emitEndedBudgetCampaign(
        address campaignPlasmaAddress,
        uint contractorLeftover,
        uint moderatorEarningsDistributed
    )
    public;


    function emitUserWithdrawnNetworkEarnings(
        address user,
        uint amountOfTokens
    )
    public;

    function emitRebalancedRewards(
        uint cycleId,
        uint difference,
        string action
    )
    public;
}

contract ITwoKeyExchangeRateContract {
    function getBaseToTargetRate(string _currency) public view returns (uint);
    function getStableCoinTo2KEYQuota(address stableCoinAddress) public view returns (uint,uint);
    function getStableCoinToUSDQuota(address stableCoin) public view returns (uint);
}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
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

contract TwoKeyDonationConversionHandler is UpgradeableCampaign, TwoKeyCampaignConversionHandler {

    Conversion [] public conversions;
    InvoiceToken public erc20InvoiceToken; // ERC20 token which will be issued as an invoice



    ITwoKeyDonationCampaign twoKeyCampaign;

    string currency;

    mapping(address => uint256) private converterToAmountOfDonationTokensReceived;


    //Struct to represent donation in Ether
    struct Conversion {
        address contractor; // Contractor (creator) of campaign
        uint256 contractorProceedsETHWei; // How much contractor will receive for this conversion
        address converter; // Converter is one who's buying tokens -> plasma address
        uint conversionCreatedAt; // Time when conversion was created
        uint conversionExpiresAt; // Time when conversion expires
        ConversionState state;
        uint256 conversionAmount; // Amount for conversion (In ETH / FIAT)
        uint256 maxReferralRewardETHWei; // Total referral reward for the conversion
        uint256 maxReferralReward2key;
        uint256 moderatorFeeETHWei;
        uint256 tokensBought;
    }

    event InvoiceTokenCreated(
        address token,
        string tokenName,
        string tokenSymbol
    );


    function setInitialParamsDonationConversionHandler(
        string tokenName,
        string tokenSymbol,
        string _currency,
        address _contractor,
        address _twoKeyDonationCampaign,
        address _twoKeySingletonRegistry
    )
    public
    {
        require(isCampaignInitialized == false);

        counters = new uint[](12);
        twoKeyCampaign = ITwoKeyDonationCampaign(_twoKeyDonationCampaign);
        twoKeySingletonRegistry = _twoKeySingletonRegistry;
        twoKeyEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource");
        contractor = _contractor;
        currency = _currency;
        // Deploy an ERC20 token which will be used as the Invoice
        erc20InvoiceToken = new InvoiceToken(tokenName,tokenSymbol,address(this));
        // Emit an event with deployed token address, name, and symbol
        emit InvoiceTokenCreated(address(erc20InvoiceToken), tokenName, tokenSymbol);
        isCampaignInitialized = true;
    }

    function setExpiryConversionInHours(
        uint _expiryConversionInHours
    )
    public
    {
        require(msg.sender == address(twoKeyCampaign));
        expiryConversionInHours = _expiryConversionInHours;
    }


    function emitConvertedEvent(
        address converterAddress,
        uint conversionAmount,
        uint conversionId
    )
    internal
    view
    {
        ITwoKeyEventSource(twoKeyEventSource).convertedDonation(
            twoKeyCampaign,
            ITwoKeyEventSource(twoKeyEventSource).plasmaOf(converterAddress),
            conversionAmount,
            conversionId
        );
    }

    function emitExecutedEvent(
        address _converterAddress,
        uint conversionId,
        uint tokens
    )
    internal
    view
    {
        ITwoKeyEventSource(twoKeyEventSource).executed(
            twoKeyCampaign,
            ITwoKeyEventSource(twoKeyEventSource).plasmaOf(_converterAddress),
            conversionId,
            tokens
        );
    }

    function emitRejectedEvent(
        address _campaignAddress,
        address _converterAddress
    )
    internal
    view
    {
        ITwoKeyEventSource(twoKeyEventSource).rejected(
            twoKeyCampaign,
            ITwoKeyEventSource(twoKeyEventSource).plasmaOf(_converterAddress)
        );
    }



    /**
     * @notice Function to calculate amount of donation tokens to be received
     * @param _conversionAmountETHWei is the amount of conversion in WEI
     */
    function calculateAmountOfTokens(
        uint _conversionAmountETHWei
    )
    internal
    view
    returns (uint)
    {
        if(keccak256(currency) == keccak256('ETH')) {
            return _conversionAmountETHWei;
        } else {
            address twoKeyExchangeRateContract = getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract");
            uint rate = ITwoKeyExchangeRateContract(twoKeyExchangeRateContract).getBaseToTargetRate(currency);
            uint conversionAmountInFIAT = (_conversionAmountETHWei*rate).div(10**18);
            return conversionAmountInFIAT;
        }
    }


    function transferInvoiceToken(
        address _converter,
        uint _conversionAmountETHWei
    )
    internal
    {
        uint amountOfTokens = calculateAmountOfTokens(_conversionAmountETHWei);
        converterToAmountOfDonationTokensReceived[_converter] = converterToAmountOfDonationTokensReceived[_converter].add(amountOfTokens);
        erc20InvoiceToken.transfer(_converter, amountOfTokens);
    }


    /**
     * @param _converterAddress is the one who calls join and donate function
     */
    function supportForCreateConversion(
        address _converterAddress,
        uint _conversionAmount,
        uint _maxReferralRewardETHWei,
        bool _isKYCRequired,
        uint _conversionAmountCampaignCurrency
    )
    public
    returns (uint)
    {
        require(msg.sender == address(twoKeyCampaign));

        handleConverterState(_converterAddress, _isKYCRequired);

        uint256 _moderatorFeeETHWei = calculateModeratorFee(_conversionAmount);
        uint256 _contractorProceeds = _conversionAmount.sub(_maxReferralRewardETHWei.add(_moderatorFeeETHWei));
        counters[1] = counters[1].add(1);

        uint amountOfTokens = calculateAmountOfTokens(_conversionAmount);

        Conversion memory c = Conversion(
            contractor,
            _contractorProceeds,
            _converterAddress,
            now,
            now.add(expiryConversionInHours.mul(1 hours)),
            ConversionState.APPROVED,
            _conversionAmount,
            _maxReferralRewardETHWei,
            0,
            _moderatorFeeETHWei,
            amountOfTokens
        );

        amountConverterSpentEthWEI[c.converter] = amountConverterSpentEthWEI[c.converter].add(c.conversionAmount);

        conversions.push(c);
        converterToHisConversions[_converterAddress].push(numberOfConversions);
        emitConvertedEvent(_converterAddress, _conversionAmount, numberOfConversions);

        conversionToCampaignCurrencyAmountAtTimeOfCreation[numberOfConversions] = _conversionAmountCampaignCurrency;
        emit ConversionCreated(numberOfConversions);
        numberOfConversions = numberOfConversions.add(1);

        return numberOfConversions-1;

    }

    function executeConversion(
        uint _conversionId
    )
    public
    {
        Conversion conversion = conversions[_conversionId];
        require(converterToState[conversion.converter] == ConverterState.APPROVED);
        require(conversion.state == ConversionState.APPROVED);

        counters[1] = counters[1].sub(1); //Decrease number of approved conversions

        uint totalReward2keys = 0;

        emitExecutedEvent(conversion.converter, _conversionId, conversion.tokensBought);


        totalReward2keys = twoKeyCampaign.buyTokensAndDistributeReferrerRewards(
            conversion.maxReferralRewardETHWei,
            conversion.converter,
            _conversionId
        );


        // Update reputation points in registry for conversion executed event
        ITwoKeyBaseReputationRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyBaseReputationRegistry")).updateOnConversionExecutedEvent(
            conversion.converter,
            contractor,
            twoKeyCampaign
        );

        counters[8] = counters[8].add(totalReward2keys);
        twoKeyCampaign.buyTokensForModeratorRewards(conversion.moderatorFeeETHWei);
        twoKeyCampaign.updateContractorProceeds(conversion.contractorProceedsETHWei);

        counters[6] = counters[6].add(conversion.conversionAmount);

        if(doesConverterHaveExecutedConversions[conversion.converter] == false) {
            counters[5] = counters[5].add(1); //increase number of unique converters
            doesConverterHaveExecutedConversions[conversion.converter] = true;
        }

        conversion.maxReferralReward2key = totalReward2keys;
        conversion.state = ConversionState.EXECUTED;
        counters[3] = counters[3].add(1); //Increase number of executed conversions

        counters[10] = counters[10].add(conversionToCampaignCurrencyAmountAtTimeOfCreation[_conversionId]);
        transferInvoiceToken(conversion.converter, conversion.conversionAmount);
        counters[11] = counters[11].add(conversion.tokensBought);

    }


    function rejectConverter(
        address _converter
    )
    public
    onlyContractorOrMaintainer
    {
        rejectConverterInternal(_converter);
        uint refundAmount = 0;
        uint len = converterToHisConversions[_converter].length;
        uint reservedInCampaignCurrencyAmount = 0;

        for(uint i=0; i<len; i++) {
            uint conversionId = converterToHisConversions[_converter][i];
            Conversion c = conversions[conversionId];

            //In this case since we don't support FIAT, every conversion is auto approved
            if(c.state == ConversionState.APPROVED) {
                counters[1] = counters[1].sub(1); // Reduce number of approved conversions
                counters[2] = counters[2].add(1); //Increase number of rejected conversions
                ITwoKeyBaseReputationRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyBaseReputationRegistry")).updateOnConversionRejectedEvent(_converter, contractor, twoKeyCampaign);
                c.state = ConversionState.REJECTED;
                refundAmount = refundAmount.add(c.conversionAmount);
                reservedInCampaignCurrencyAmount = reservedInCampaignCurrencyAmount.add(conversionToCampaignCurrencyAmountAtTimeOfCreation[conversionId]);
            }
        }

        if(refundAmount > 0) {
            twoKeyCampaign.sendBackEthWhenConversionCancelledOrRejected(_converter, refundAmount);
        }

        // Release for Total raised requirement
        if(reservedInCampaignCurrencyAmount > 0) {
            address logicHandler = twoKeyCampaign.logicHandler();
            ITwoKeyCampaignLogicHandler(logicHandler).reduceTotalRaisedFundsAfterConversionRejected(reservedInCampaignCurrencyAmount);
        }

        emitRejectedEvent(twoKeyCampaign, _converter);
    }

    /**
     * @notice Function to cancel conversion and get back money
     * @param _conversionId is the id of the conversion
     * @dev returns all the funds to the converter back
     */
    function converterCancelConversion(
        uint _conversionId
    )
    public
    {
        Conversion conversion = conversions[_conversionId];

        require(conversion.conversionExpiresAt <= block.timestamp);
        require(msg.sender == conversion.converter);

        if(conversion.state == ConversionState.PENDING_APPROVAL) {
            counters[0] = counters[0].sub(1); // Reduce number of pending conversions
        } else if (conversion.state == ConversionState.APPROVED) {
            counters[1] = counters[1].sub(1); // Reduce number of approved conversions
        } else {
            revert(); // If conversion is not in either pending or approved state it can't be cancelled
        }
        counters[4] = counters[4].add(1); // Increase number of cancelled conversions
        conversion.state = ConversionState.CANCELLED_BY_CONVERTER;


        twoKeyCampaign.sendBackEthWhenConversionCancelledOrRejected(msg.sender, conversion.conversionAmount);
    }


    /**
     * @notice Function to get conversion details by id
     * @param conversionId is the id of conversion
     */
    function getConversion(
        uint conversionId
    )
    external
    view
    returns (bytes)
    {
        Conversion memory conversion = conversions[conversionId];

        address converter; // Defaults to 0x0

        if(isConverterAnonymous[conversion.converter] == false) {
            converter = conversion.converter;
        }

        return abi.encodePacked (
            conversion.contractor,
            converter,
            conversion.contractorProceedsETHWei,
            conversion.conversionAmount,
            conversion.tokensBought,
            conversion.maxReferralRewardETHWei,
            conversion.maxReferralReward2key,
            conversion.moderatorFeeETHWei,
            conversion.state
        );
    }

    function getAmountConverterSpent(
        address converter
    )
    public
    view
    returns (uint)
    {
        return amountConverterSpentEthWEI[converter];
    }

    function getAmountOfDonationTokensConverterReceived(
        address converter
    )
    public
    view
    returns (uint)
    {
        return converterToAmountOfDonationTokensReceived[converter];
    }

}

