pragma solidity ^0.4.24;

import "../../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/IKyberNetworkProxy.sol";
import "../interfaces/storage-contracts/ITwoKeyUpgradableExchangeStorage.sol";
import "../interfaces/IERC20.sol";

import "../libraries/SafeMath.sol";
import "../libraries/GetCode.sol";
import "../libraries/SafeERC20.sol";
import "../upgradability/Upgradeable.sol";
import "./ITwoKeySingletonUtils.sol";


contract TwoKeyUpgradableExchange is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    bool initialized;

    ITwoKeyUpgradableExchangeStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Event will be fired every time someone buys tokens
     */
    event TokenSell(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );


    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param receiver is who got the tokens
     * @param weiReceived is how weis paid for purchase
     * @param tokensBought is the amount of tokens purchased
     * @param rate is the global variable rate on the contract
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed receiver,
        uint256 weiReceived,
        uint256 tokensBought,
        uint256 rate
    );


    /**
     * @notice This event will be fired every time a withdraw is executed
     */
    event WithdrawExecuted(
        address caller,
        address beneficiary,
        uint stableCoinsReserveBefore,
        uint stableCoinsReserveAfter,
        uint etherBalanceBefore,
        uint etherBalanceAfter,
        uint stableCoinsToWithdraw,
        uint twoKeyAmount
    );


    /**
     * @notice Constructor of the contract, can be called only once
     * @param _token is ERC20 2key token
     * @param _daiAddress is the address of DAI on ropsten
     * @param _kyberNetworkProxy is the address of Kyber network contract
     * @param _twoKeySingletonesRegistry is the address of TWO_KEY_SINGLETON_REGISTRY
     * @param _proxyStorageContract is the address of proxy of storage contract
     */
    function setInitialParams(
        ERC20 _token,
        address _daiAddress,
        address _kyberNetworkProxy,
        address _twoKeySingletonesRegistry,
        address _proxyStorageContract
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyUpgradableExchangeStorage(_proxyStorageContract);
        setUint(keccak256("buyRate2key"),95);// When anyone send 2key to contract, 2key in exchange will be calculated on it's buy rate
        setUint(keccak256("sellRate2key"),100);// When anyone send Ether to contract, 2key in exchange will be calculated on it's sell rate
        setUint(keccak256("weiRaised"),0);
        setUint(keccak256("numberOfContracts"), 0); //Number of contracts which have interacted with this contract through buyTokens function

        setAddress(keccak256("TWO_KEY_TOKEN"),address(_token));
        setAddress(keccak256("DAI"), _daiAddress);
        setAddress(keccak256("ETH_TOKEN_ADDRESS"), 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
        setAddress(keccak256("KYBER_NETWORK_PROXY"), _kyberNetworkProxy);

        initialized = true;
    }

    /**
     * @notice Modifier which will validate if contract is allowed to buy tokens
     */
    modifier onlyValidatedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry("TwoKeyCampaignValidator");
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }


    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    private
    {
        require(_beneficiary != address(0),'beneficiary address can not be 0' );
        require(_weiAmount != 0, 'wei amount can not be 0');
    }


    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        //Take the address of token from storage
        address tokenAddress = getAddress(keccak256("TWO_KEY_TOKEN"));

        ERC20(tokenAddress).safeTransfer(_beneficiary, _tokenAmount);
    }


    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }


    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmountToBeSold(
        uint256 _weiAmount
    )
    public
    view
    returns (uint256)
    {
        address twoKeyExchangeRateContract = getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract");

        uint rate = ITwoKeyExchangeRateContract(twoKeyExchangeRateContract).getBaseToTargetRate("USD");
        return (_weiAmount*rate).mul(1000).div(sellRate2key()).div(10**18);
    }


    /**
     * @notice Function to calculate how many stable coins we can get for specific amount of 2keys
     * @dev This is happening in case we're receiving (buying) 2key
     * @param _2keyAmount is the amount of 2keys sent to the contract
     */
    function _getUSDStableCoinAmountFrom2keyUnits(
        uint256 _2keyAmount
    )
    public
    view
    returns (uint256)
    {
        // Take the address of TwoKeyExchangeRateContract
        address twoKeyExchangeRateContract = getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract");

        // This is the case when we buy 2keys in exchange for stable coins
        uint rate = ITwoKeyExchangeRateContract(twoKeyExchangeRateContract).getBaseToTargetRate("USD-DAI"); // 1.01
        uint lowestAcceptedRate = 96;
        require(rate >= lowestAcceptedRate.mul(10**18).div(100)); // Require that lowest accepted rate is greater than 0.95

        uint buyRate2keys = buyRate2key();

        uint dollarWeiWorthTokens = _2keyAmount.mul(buyRate2keys).div(1000);  // 100*95/1000 = 9.5
        uint amountOfDAIs = dollarWeiWorthTokens.mul(rate).div(10**18);      // 9.5 * 1.01 =vOK

        return amountOfDAIs;
    }


    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(
        address _twoKeyAdmin
    )
    internal
    {
        _twoKeyAdmin.transfer(msg.value);
    }


    /**
     * @notice Function to buyTokens
     * @param _beneficiary to get
     * @return amount of tokens bought
     */
    function buyTokens(
        address _beneficiary
    )
    public
    payable
    onlyValidatedContracts
    returns (uint)
    {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmountToBeSold(weiAmount);

        // update state
        bytes32 weiRaisedKeyHash = keccak256("weiRaised");
        uint weiRaised = getUint(weiRaisedKeyHash).add(weiAmount);
        setUint(weiRaisedKeyHash,weiRaised);

        // check if contract is first time interacting with this one
        uint contractId = getContractId(msg.sender);

        if(contractId == 0) {
            contractId = addNewContract(msg.sender);
        }

        bytes32 ethReceivedFromContractKeyHash = keccak256("ethReceivedFromContract", contractId);
        setUint(ethReceivedFromContractKeyHash, ethReceivedFromContract(contractId).add(msg.value));

        bytes32 sent2keyToContractKeyHash = keccak256("sent2keyToContract", contractId);
        setUint(sent2keyToContractKeyHash, sent2keyToContract(contractId).add(tokens));

        updateEthWeiAvailableToHedge(contractId, msg.value);

        _processPurchase(_beneficiary, tokens);


        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens,
            sellRate2key()
        );

        return tokens;
    }



    /**
     * @notice Function to calculate available to hedge sum on all contracts
     */
    function calculateSumOnAllContracts()
    public //Will be internal after we test it
    view
    returns (uint)
    {
        uint numberOfContractsCurrently = numberOfContracts();
        uint sumOfAmounts = 0; //Will represent total sum we have on the contract
        uint i;

        // Sum all amounts on all contracts
        for(i=1; i<=numberOfContractsCurrently; i++) {
            sumOfAmounts = sumOfAmounts.add(ethWeiAvailableToHedge(i));
        }
        return sumOfAmounts;
    }

    /**
     * @notice Function to calculate how much percentage will be deducted from values
     */
    function calculatePercentageToDeduct(
        uint _ethWeiHedged,
        uint _sumOfAmounts
    )
    public
    view
    returns (uint)
    {
        return _ethWeiHedged.mul(10**18).div(_sumOfAmounts);
    }

    /**
     * @notice Function to calculate ratio between eth and dai in WEI's
     */
    function calculateRatioBetweenDAIandETH(
        uint _ethWeiHedged,
        uint _daiReceived
    )
    public
    view
    returns (uint)
    {
        return _daiReceived.mul(10**18).div(_ethWeiHedged);
    }

    /**
     * TODO: REMOVE ONCE TESTING DONE.
     */
    function testingFunction(
        uint ethWei,
        uint dai)
    public
    {
        reduceHedgedAmountFromContractsAndIncreaseDaiAvailable(ethWei, dai);
    }

    /**
     * @notice Function to reduce available amount to hedge and increase available DAI to withdraw
     * @param _ethWeiHedged is how much eth was hedged
     * @param _daiReceived is how much DAI's we got for that hedging
     */
    function reduceHedgedAmountFromContractsAndIncreaseDaiAvailable(
        uint _ethWeiHedged,
        uint _daiReceived
    )
    internal
    {
        uint numberOfContractsCurrently = numberOfContracts();
        uint sumOfAmounts = calculateSumOnAllContracts(); //Will represent total sum we have on the contract
        uint i;

        uint percentageToDeductWei = calculatePercentageToDeduct(_ethWeiHedged, sumOfAmounts); // Percentage to deduct in WEI (less than 1)

        // Representing how much ETH is 1 DAI (DAI/ETH)
        uint ratio = calculateRatioBetweenDAIandETH(_ethWeiHedged, _daiReceived);

        for(i=1; i<=numberOfContractsCurrently; i++) {
            if(ethWeiAvailableToHedge(i) > 0) {
                uint currentEthWEIAvailableForContractI = ethWeiAvailableToHedge(i);
                uint hundredPercentWei = 10**18;
                uint afterHedgingAvailableEthWei = currentEthWEIAvailableForContractI.mul(hundredPercentWei.sub(percentageToDeductWei)).div(10**18);

                uint hedgedEthWei = currentEthWEIAvailableForContractI.sub(afterHedgingAvailableEthWei);
                uint daisReceived = hedgedEthWei.mul(ratio).div(10**18);
                updateAccountingValues(daisReceived, hedgedEthWei, afterHedgingAvailableEthWei, i);
            }
        }
    }

    function updateAccountingValues(
        uint _daisReceived,
        uint _hedgedEthWei,
        uint _afterHedgingAvailableEthWei,
        uint _contractID
    )
    internal
    {
        bytes32 ethWeiAvailableToHedgeKeyHash = keccak256("ethWeiAvailableToHedge", _contractID);
        bytes32 daiWeiAvailableToWithdrawKeyHash = keccak256("daiWeiAvailableToWithdraw", _contractID);
        bytes32 ethWeiHedgedPerContractKeyHash = keccak256("ethWeiHedgedPerContract", _contractID);
        bytes32 daiWeiReceivedFromHedgingPerContractKeyHash = keccak256("daiWeiReceivedFromHedgingPerContract",_contractID);

        setUint(daiWeiReceivedFromHedgingPerContractKeyHash, daiWeiReceivedFromHedgingPerContract(_contractID).add(_daisReceived));
        setUint(ethWeiHedgedPerContractKeyHash, ethWeiHedgedPerContract(_contractID).add(_hedgedEthWei));
        setUint(ethWeiAvailableToHedgeKeyHash, _afterHedgingAvailableEthWei);
        setUint(daiWeiAvailableToWithdrawKeyHash, daiWeiAvailableToWithdraw(_contractID).add(_daisReceived));
    }

    /**
     * @notice Setter for EthWeiAvailableToHedge
     * @param _contractID is the ID of the contract
     * @param _msgValue is the amount sent
     */
    function updateEthWeiAvailableToHedge(
        uint _contractID,
        uint _msgValue
    )
    internal {
        // Update EthWeiAvailableToHedge per contract
        bytes32 ethWeiAvailableToHedgeKeyHash = keccak256("ethWeiAvailableToHedge", _contractID);
        setUint(ethWeiAvailableToHedgeKeyHash, getUint(ethWeiAvailableToHedgeKeyHash).add(_msgValue));
    }


    /**
     * @notice Function to register new contract with corresponding ID
     * @param _contractAddress is the address of the contract we're adding
     */
    function addNewContract(
        address _contractAddress
    )
    internal
    returns (uint)
    {
        // Get number of currently different contracts and increment by 1
        uint numberOfContractsExisting = numberOfContracts();
        uint id = numberOfContractsExisting.add(1);

        bytes32 keyHashContractAddressToId = keccak256("contractAddressToId", _contractAddress);
        bytes32 keyHashIdToContractAddress = keccak256("idToContractAddress", id);

        // Set mappings id=>contractAddress and contractAddress=>id
        setUint(keyHashContractAddressToId, id);
        setAddress(keyHashIdToContractAddress, _contractAddress);

        // Increment number of existing contracts
        setUint(keccak256("numberOfContracts"), id);

        // Return contract ID
        return id;
    }

    /**
     * @notice Function to get contract id, if return 0 means contract is not existing
     */
    function getContractId(
        address _contractAddress
    )
    public
    view
    returns (uint) {
        bytes32 keyHashContractAddressToId = keccak256("contractAddressToId", _contractAddress);
        uint id = getUint(keyHashContractAddressToId);
        return id;
    }


    /**
     * @notice Function to get expected rate from Kyber contract
     * @param amountEthWei is the amount we'd like to exchange
     * @return if the value is 0 that means we can't
     */
    function getKyberExpectedRate(
        uint amountEthWei
    )
    public
    view
    returns (uint)
    {
        address kyberProxyContract = getAddress(keccak256("KYBER_NETWORK_PROXY"));
        IKyberNetworkProxy proxyContract = IKyberNetworkProxy(kyberProxyContract);

        ERC20 eth = ERC20(getAddress(keccak256("ETH_TOKEN_ADDRESS")));
        ERC20 dai = ERC20(getAddress(keccak256("DAI")));

        uint minConversionRate;
        (minConversionRate,) = proxyContract.getExpectedRate(eth, dai, amountEthWei);

        return minConversionRate;
    }


    /**
     * @notice Function to start hedging some ether amount
     * @param amountToBeHedged is the amount we'd like to hedge
     * @dev only maintainer can call this function
     */
    function startHedging(
        uint amountToBeHedged,
        uint approvedMinConversionRate
    )
    public
    onlyMaintainer
    {
        ERC20 dai = ERC20(getAddress(keccak256("DAI")));

        address kyberProxyContract = getAddress(keccak256("KYBER_NETWORK_PROXY"));
        IKyberNetworkProxy proxyContract = IKyberNetworkProxy(kyberProxyContract);

        uint minConversionRate = getKyberExpectedRate(amountToBeHedged);
        require(minConversionRate >= approvedMinConversionRate.mul(95).div(100)); //Means our rate can be at most same as their rate, because they're giving the best rate
        uint stableCoinUnits = proxyContract.swapEtherToToken.value(amountToBeHedged)(dai,minConversionRate);

        reduceHedgedAmountFromContractsAndIncreaseDaiAvailable(amountToBeHedged, stableCoinUnits);
    }

    /**
     * @notice Function which will be called by 2key campaigns if user wants to withdraw his earnings in stableCoins
     * @param _twoKeyUnits is the amount of 2key tokens which will be taken from campaign
     * @param _beneficiary is the user who will receive the tokens
     */
    function buyStableCoinWith2key(
        uint _twoKeyUnits,
        address _beneficiary
    )
    external
    onlyValidatedContracts
    {
        ERC20 dai = ERC20(getAddress(keccak256("DAI")));
        ERC20 token = ERC20(getAddress(keccak256("TWO_KEY_TOKEN")));

        uint stableCoinUnits = _getUSDStableCoinAmountFrom2keyUnits(_twoKeyUnits);
        uint etherBalanceOnContractBefore = this.balance;
        uint stableCoinsOnContractBefore = dai.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), _twoKeyUnits);

        uint stableCoinsAfter = stableCoinsOnContractBefore.sub(stableCoinUnits);

        emitEventWithdrawExecuted(
            _beneficiary,
            stableCoinsOnContractBefore,
            stableCoinsAfter,
            etherBalanceOnContractBefore,
            stableCoinUnits,
            _twoKeyUnits
        );

        dai.transfer(_beneficiary, stableCoinUnits);
    }

    /**
     * @notice Function to emit an event, created separately because of stack depth
     */
    function emitEventWithdrawExecuted(
        address _beneficiary,
        uint _stableCoinsOnContractBefore,
        uint _stableCoinsAfter,
        uint _etherBalanceOnContractBefore,
        uint _stableCoinUnits,
        uint twoKeyUnits
    )
    internal
    {
        emit WithdrawExecuted(
            msg.sender,
            _beneficiary,
            _stableCoinsOnContractBefore,
            _stableCoinsAfter,
            _etherBalanceOnContractBefore,
            this.balance,
            _stableCoinUnits,
            twoKeyUnits
        );
    }

    /**
     * @notice Function to return number of campaign contracts (different) interacted with this contract
     */
    function numberOfContracts() public view returns (uint) {
        return getUint(keccak256("numberOfContracts"));
    }

    /**
     * @notice Function to get Eth2DAI average exchange rate per contract
     * @param _contractID is the ID of the contract we're requesting information
     */
    function getEth2DaiAverageExchangeRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        uint ethWeiHedgedPerContractByNow = ethWeiHedgedPerContract(_contractID); //total hedged
        uint daiWeiReceivedFromHedgingPerContractByNow = daiWeiReceivedFromHedgingPerContract(_contractID); //total received
        // Average weighted by eth
        return daiWeiReceivedFromHedgingPerContractByNow.mul(10**18).div(ethWeiHedgedPerContractByNow);
    }


    /**
     * @notice Function to get Eth22key average exchange rate per contract
     * @param _contractID is the ID of the contract we're requesting information
     */
    function getEth2KeyAverageRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        uint ethReceivedFromContractByNow = ethReceivedFromContract(_contractID);
        uint sent2keyToContractByNow = sent2keyToContract(_contractID);
        // Average weighted by eth
        return sent2keyToContractByNow.mul(10**18).div(ethReceivedFromContractByNow);
    }

    /**
     * @notice Function to get eth received from contract for specific contract ID
     * @param _contractID is the ID of the contract we're requesting information
     */
    function ethReceivedFromContract(
        uint _contractID
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("ethReceivedFromContract", _contractID));
    }

    /**
     * @notice Function to get how many 2keys are sent to selected contract
     * @param _contractID is the ID of the contract we're requesting information
     */
    function sent2keyToContract(
        uint _contractID
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("sent2keyToContract", _contractID));
    }


    /**
     * @notice Function to get how much ethWei hedged per contract
     * @param _contractID is the ID of the contract we're requesting information
     */
    function ethWeiHedgedPerContract(
        uint _contractID
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("ethWeiHedgedPerContract", _contractID));
    }


    /**
     * @notice Function to determine how many dai received from hedging per contract
     * @param _contractID is the ID of the contract we're requesting information
     */
    function daiWeiReceivedFromHedgingPerContract(
        uint _contractID
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("daiWeiReceivedFromHedgingPerContract", _contractID));
    }

    /**
     * @notice Getter for mapping "daiWeiAvailableToWithdraw" (per contract)
     */
    function daiWeiAvailableToWithdraw(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256("daiWeiAvailableToWithdraw", _contractID));
    }

    /**
     * @notice Getter for "mapping" ethWeiAvailableToHedge (per contract)
     */
    function ethWeiAvailableToHedge(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256("ethWeiAvailableToHedge", _contractID));
    }

    /**
     * @notice Getter for 2key buy rate
     */
    function buyRate2key() public view returns (uint) {
        return getUint(keccak256("buyRate2key"));
    }

    /**
     * @notice Getter for 2key sell rate
     */
    function sellRate2key() public view returns (uint) {
        return getUint(keccak256("sellRate2key"));
    }

    /**
     * @notice Getter for weiRaised
     */
    function weiRaised() public view returns (uint) {
        return getUint(keccak256("weiRaised"));
    }

    // Internal wrapper methods
    function getUint(bytes32 key) internal view returns (uint) {
        return PROXY_STORAGE_CONTRACT.getUint(key);
    }

    // Internal wrapper methods
    function setUint(bytes32 key, uint value) internal {
        PROXY_STORAGE_CONTRACT.setUint(key, value);
    }

    //Internal wrapper method
    function getBool(bytes32 key) internal view returns (bool) {
        PROXY_STORAGE_CONTRACT.getBool(key);
    }

    //Internal wrapper method
    function setBool(bytes32 key, bool value) internal {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }

    // Internal wrapper methods
    function getAddress(bytes32 key) internal view returns (address) {
        return PROXY_STORAGE_CONTRACT.getAddress(key);
    }

    // Internal wrapper methods
    function setAddress(bytes32 key, address value) internal {
        PROXY_STORAGE_CONTRACT.setAddress(key, value);
    }

    /**
     * @notice Function where maintainer can update any unassigned integer value
     */
    function updateUint(
        string key,
        uint value
    )
    public
    onlyMaintainer
    {
        bytes32 keyHash = keccak256(key);
        setUint(keyHash, value);
    }

    /**
     * @notice Withdraw all ether from contract
     */
    function withdrawEther()
    public
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        require(msg.sender == twoKeyAdmin);
        _forwardFunds(twoKeyAdmin);
    }


    /**
     * @notice Function to withdraw any ERC20 tokens to TwoKeyAdmin
     */
    function withdrawERC20(
        address _erc20TokenAddress,
        uint _tokenAmount
    )
    public
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        require(msg.sender == twoKeyAdmin);
        ERC20(_erc20TokenAddress).safeTransfer(twoKeyAdmin, _tokenAmount);

    }


    /**
     * @notice Fallback function to handle incoming ether
     */
    function ()
    public
    payable
    {

    }

}
