pragma solidity ^0.4.24;


import "../ERC20/ERC20.sol";

import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/IKyberNetworkProxy.sol";
import "../interfaces/IKyberReserveInterface.sol";
import "../interfaces/storage-contracts/ITwoKeyUpgradableExchangeStorage.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyFeeManager.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/ITwoKeyFactory.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../upgradability/Upgradeable.sol";


import "../libraries/SafeMath.sol";
import "../libraries/GetCode.sol";
import "../libraries/PriceDiscovery.sol";

import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";


contract TwoKeyUpgradableExchange is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for uint256;

    bool initialized;
    address constant ETH_TOKEN_ADDRESS = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
    string constant _twoKeyEconomy = "TwoKeyEconomy";
    string constant _twoKeyExchangeRateContract = "TwoKeyExchangeRateContract";
    string constant _twoKeyAdmin = "TwoKeyAdmin";
    string constant _kyberNetworkProxy = "KYBER_NETWORK_PROXY";
    string constant _kyberReserveContract = "KYBER_RESERVE_CONTRACT";


    ITwoKeyUpgradableExchangeStorage public PROXY_STORAGE_CONTRACT;



    /**
     * @notice          This event will be fired every time a withdraw is executed
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


    event HedgedEther (
        uint _daisReceived,
        uint _ratio,
        uint _numberOfContracts
    );

    /**
     * @notice          Constructor of the contract, can be called only once
     *
     * @param           _daiAddress is the address of DAI on ropsten
     * @param           _kyberNetworkProxyAddress is the address of Kyber network contract
     * @param           _twoKeySingletonesRegistry is the address of TWO_KEY_SINGLETON_REGISTRY
     * @param           _proxyStorageContract is the address of proxy of storage contract
     */
    function setInitialParams(
        address _daiAddress,
        address _kyberNetworkProxyAddress,
        address _twoKeySingletonesRegistry,
        address _proxyStorageContract
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyUpgradableExchangeStorage(_proxyStorageContract);
        setUint(keccak256("spreadWei"), 3**16); // 3% wei

        setUint(keccak256("sellRate2key"),6 * (10**16));// When anyone send Ether to contract, 2key in exchange will be calculated on it's sell rate
        setUint(keccak256("numberOfContracts"), 0); //Number of contracts which have interacted with this contract through buyTokens function

        setAddress(keccak256(_kyberNetworkProxy), _kyberNetworkProxyAddress);

        initialized = true;
    }


    /**
     * @notice          Modifier which will validate if contract is allowed to buy tokens
     */
    modifier onlyValidatedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }


    /**
     * @notice          Modifier which will validate if msg sender is TwoKeyAdmin contract
     */
    modifier onlyTwoKeyAdmin {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        require(msg.sender == twoKeyAdmin);
        _;
    }


    /**
     * @dev             Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     *                  Use `super` in contracts that inherit from Crowdsale to extend their validations.
     *
     * @param           _beneficiary Address performing the token purchase
     * @param           _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    private
    {
        require(_weiAmount != 0);
    }


    /**
     * @dev             Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param           _beneficiary Address performing the token purchase
     * @param           _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        //Take the address of token from storage
        address tokenAddress = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
        ERC20(tokenAddress).transfer(_beneficiary, _tokenAmount);
    }


    /**
     * @dev             Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param           _beneficiary Address receiving the tokens
     * @param           _tokenAmount Number of tokens to be purchased
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
     * @notice          Function to calculate how much pnercentage will be deducted from values
     */
    function calculatePercentageToDeduct(
        uint _ethWeiHedged,
        uint _sumOfAmounts
    )
    internal
    view
    returns (uint)
    {
        return _ethWeiHedged.mul(10**18).div(_sumOfAmounts);
    }


    /**
     * @notice          Function to calculate ratio between eth and dai in WEI's
     */
    function calculateRatioBetweenDAIandETH(
        uint _ethWeiHedged,
        uint _daiReceived
    )
    internal
    view
    returns (uint)
    {
        return _daiReceived.mul(10**18).div(_ethWeiHedged);
    }


    /**
     * @notice          Setter for EthWeiAvailableToHedge
     * @param           _contractID is the ID of the contract
     * @param           _msgValue is the amount sent
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
     * @notice          Function to register new contract with corresponding ID
     * @param           _contractAddress is the address of the contract we're adding
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
     * @notice          Function to emit an event, created separately because of stack depth
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
     * @notice          Internal function to get uint from storage contract
     *
     * @param           key is the to which value is allocated in storage
     */
    function getUint(
        bytes32 key
    )
    internal
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(key);
    }


    /**
     * @notice          Internal function to set uint on the storage contract
     *
     * @param           key is the key to which value is (will be) allocated in storage
     * @param           value is the value (uint) we're saving in the state
     */
    function setUint(
        bytes32 key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(key, value);
    }


    /**
     * @notice          Internal function to get bool from storage contract
     *
     * @param           key is the to which value is allocated in storage
     */
    function getBool(
        bytes32 key
    )
    internal
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(key);
    }


    /**
     * @notice          Internal function to set boolean on the storage contract
     *
     * @param           key is the key to which value is (will be) allocated in storage
     * @param           value is the value (boolean) we're saving in the state
     */
    function setBool(
        bytes32 key,
        bool value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }


    /**
     * @notice          Internal function to get address from storage contract
     *
     * @param           key is the to which value is allocated in storage
     */
    function getAddress(
        bytes32 key
    )
    internal
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(key);
    }


    /**
     * @notice          Internal function to set address on the storage contract
     *
     * @param           key is the key to which value is (will be) allocated in storage
     * @param           value is the value (address) we're saving in the state
     */
    function setAddress(
        bytes32 key,
        address value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddress(key, value);
    }


    /**
     * @notice          Function to get eth received from contract for specific contract ID
     *
     * @param           _contractID is the ID of the contract we're requesting information
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
     * @notice          Function to get how many 2keys are sent to selected contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
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
     * @notice          Function to get how much ethWei hedged per contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
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
     * @notice          Function to determine how many dai received from hedging per contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
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
     * @notice          Function to report that 2KEY tokens are withdrawn from the network
     *
     * @param           amountOfTokensWithdrawn is the amount of tokens he wants to withdraw
     * @param           _contractID is the id of the contract
     */
    function report2KEYWithdrawnFromNetworkInternal(
        uint amountOfTokensWithdrawn,
        uint _contractID
    )
    internal
    {
        bytes32 _daiWeiAvailableToWithdrawKeyHash = keccak256("daiWeiAvailableToWithdraw",_contractID);
        bytes32 _daiWeiAvailableToFill2KEYReserveKeyHash = keccak256("daiWeiAvailableToFill2KEYReserve");

        uint _daiWeiAvailable = daiWeiAvailableToWithdraw(_contractID);
        uint _daiWeiToReduceFromAvailableAndFillReserve = getUSDStableCoinAmountFrom2keyUnits(amountOfTokensWithdrawn, _contractID);

        uint _daiWeiAvailableToFill2keyReserveCurrently = daiWeiAvailableToFill2KEYReserve();

        setUint(_daiWeiAvailableToFill2KEYReserveKeyHash, _daiWeiAvailableToFill2keyReserveCurrently.add(_daiWeiToReduceFromAvailableAndFillReserve));
        setUint(_daiWeiAvailableToWithdrawKeyHash, _daiWeiAvailable.sub(_daiWeiToReduceFromAvailableAndFillReserve));

        // Emit the event that DAI is released
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitDAIReleasedAsIncome(
            msg.sender,
            _daiWeiToReduceFromAvailableAndFillReserve
        );
    }

    function updateWithdrawOrReservePoolDependingOnCampaignType(
        uint contractID,
        uint _daisReceived,
        address twoKeyFactory
    )
    internal
    {
        address campaignAddress = getContractAddressFromID(contractID);
        string memory campaignType = ITwoKeyFactory(twoKeyFactory).addressToCampaignType(campaignAddress);
        if(keccak256("CPC_PUBLIC") == keccak256(campaignType)) {
            // Means everything gets immediately released to support filling reserve
            bytes32 daiWeiAvailableToFill2KEYReserveKeyHash = keccak256("daiWeiAvailableToFill2KEYReserve");
            setUint(daiWeiAvailableToFill2KEYReserveKeyHash, _daisReceived.add(getUint(daiWeiAvailableToFill2KEYReserveKeyHash)));
        } else {
            // Means funds are being able to withdrawn by influencers
            bytes32 daiWeiAvailableToWithdrawKeyHash = keccak256("daiWeiAvailableToWithdraw", contractID);
            setUint(daiWeiAvailableToWithdrawKeyHash, daiWeiAvailableToWithdraw(contractID).add(_daisReceived));
        }
    }

    /**
     * @notice          Internal function created to update specific values, separated because of stack depth
     *
     * @param           _daisReceived is the amount of received dais
     * @param           _hedgedEthWei is the amount of ethWei hedged
     * @param           _afterHedgingAvailableEthWei is the amount available after hedging
     * @param           _contractID is the ID of the contract
     */
    function updateAccountingValues(
        uint _daisReceived,
        uint _hedgedEthWei,
        uint _afterHedgingAvailableEthWei,
        uint _contractID
    )
    internal
    {
        bytes32 ethWeiAvailableToHedgeKeyHash = keccak256("ethWeiAvailableToHedge", _contractID);
        bytes32 ethWeiHedgedPerContractKeyHash = keccak256("ethWeiHedgedPerContract", _contractID);
        bytes32 daiWeiReceivedFromHedgingPerContractKeyHash = keccak256("daiWeiReceivedFromHedgingPerContract",_contractID);

        setUint(daiWeiReceivedFromHedgingPerContractKeyHash, daiWeiReceivedFromHedgingPerContract(_contractID).add(_daisReceived));
        setUint(ethWeiHedgedPerContractKeyHash, ethWeiHedgedPerContract(_contractID).add(_hedgedEthWei));
        setUint(ethWeiAvailableToHedgeKeyHash, _afterHedgingAvailableEthWei);
    }

    /**
     * @notice          Function to reduce amount of dai available to be withdrawn from selected contract
     *
     * @param           contractAddress is the address of the contract
     * @param           daiAmount is the amount of dais
     */
    function reduceDaiWeiAvailableToWithdraw(
        address contractAddress,
        uint daiAmount
    )
    internal
    {
        uint contractId = getContractId(contractAddress);
        bytes32 keyHashDaiWeiAvailableToWithdraw = keccak256('daiWeiAvailableToWithdraw', contractId);
        setUint(keyHashDaiWeiAvailableToWithdraw, daiWeiAvailableToWithdraw(contractId).sub(daiAmount));
    }


    /**
     * @notice          Function to pay Fees to a manager and transfer the tokens forward to the referrers
     *
     * @param           _beneficiary is the address who's receiving tokens
     * @param           _contractId is the id of the contract
     * @param           _totalStableCoins is the total amount of DAIs
     */
    function payFeesToManagerAndTransferTokens(
        address _beneficiary,
        uint _contractId,
        uint _totalStableCoins,
        ERC20 dai
    )
    internal
    {
        address _userPlasma = ITwoKeyReg(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry")).getEthereumToPlasma(_beneficiary);
        // Handle if there's any existing debt
        address twoKeyFeeManager = getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager");
        uint usersDebtInEth = ITwoKeyFeeManager(twoKeyFeeManager).getDebtForUser(_userPlasma);
        uint amountToPay = 0;

        if(usersDebtInEth > 0) {
            uint eth2DAI = getEth2DaiAverageExchangeRatePerContract(_contractId); // DAI / ETH
            uint totalDebtInDAI = (usersDebtInEth.mul(eth2DAI)).div(10**18); // ETH * (DAI/ETH) = DAI

            amountToPay = totalDebtInDAI;

            if (_totalStableCoins > totalDebtInDAI){
                if(_totalStableCoins < 3 * totalDebtInDAI) {
                    amountToPay = totalDebtInDAI / 2;
                }
            }
            else {
                amountToPay = _totalStableCoins / 4;
            }

            // Funds are going to admin
            dai.transfer(getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin"), amountToPay);
            ITwoKeyFeeManager(twoKeyFeeManager).payDebtWithDAI(_userPlasma, totalDebtInDAI, amountToPay);
        }

        dai.transfer(_beneficiary, _totalStableCoins.sub(amountToPay)); // Transfer the rest of the DAI to users
    }


    /**
     * @notice          Function to calculate available to hedge sum on all contracts
     */
    function calculateSumOnContracts(
        uint startIndex,
        uint endIndex
    )
    public
    view
    returns (uint)
    {
        uint sumOfAmounts = 0; //Will represent total sum we have on the contract
        uint i;

        // Sum all amounts on all contracts
        for(i=startIndex; i<=endIndex; i++) {
            sumOfAmounts = sumOfAmounts.add(ethWeiAvailableToHedge(i));
        }
        return sumOfAmounts;
    }


    /**
     * @notice          Function to get contract id, if return 0 means contract is not existing
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
     * @notice          Function to calculate how many stable coins we can get for specific amount of 2keys
     *
     * @dev             This is happening in case we're receiving (buying) 2key
     *
     * @param           _2keyAmount is the amount of 2keys sent to the contract
     * @param           _campaignID is the ID of the campaign
     */
    function getUSDStableCoinAmountFrom2keyUnits(
        uint256 _2keyAmount,
        uint _campaignID
    )
    public
    view
    returns (uint256)
    {
        uint activeHedgeRate = get2KEY2DAIHedgedRate(_campaignID);

        uint hundredPercent = 10**18;
        uint rateWithSpread = activeHedgeRate.mul(hundredPercent.sub(spreadWei())).div(10**18);
        uint amountOfDAIs = _2keyAmount.mul(rateWithSpread).div(10**18);

        return amountOfDAIs;
    }


    function getMore2KeyTokensForRebalancingV1(
        uint amountOfTokensRequested
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));
        _processPurchase(msg.sender, amountOfTokensRequested);
    }

    function returnTokensBackToExchangeV1(
        uint amountOfTokensToReturn
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));
        // Take the tokens from the contract
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy)).transferFrom(
            msg.sender,
            address(this),
            amountOfTokensToReturn
        );
    }


    /**
     * @notice          Function to buyTokens from TwoKeyUpgradableExchange
     * @param           _beneficiary is the address which will receive the tokens
     * @return          amount of tokens bought
     */
    function buyTokens(
        address _beneficiary
    )
    public
    payable
    onlyValidatedContracts
    returns (uint,uint)
    {
        uint value = msg.value;

        _preValidatePurchase(_beneficiary, value);

        address [] memory path = new address[](2);

        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        // The path is WETH -> 2KEY
        path[0] = IUniswapV2Router02(uniswapRouter).WETH();
        path[1] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");


        // Get amount of tokens receiving
        uint totalTokensBought = buyRate2Key(
            uniswapRouter,
            value,
            path
        );

        address twoKeyExchangeRateContract = getAddressFromTwoKeySingletonRegistry(_twoKeyExchangeRateContract);

        // Get the rate for eth-usd
        uint eth_usdRate = ITwoKeyExchangeRateContract(getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract"))
            .getBaseToTargetRate("USD");

        // Compute input in USD
        uint inputUSD = value.mul(eth_usdRate).div(10**18);

        // Compute token price for purchase in USD
        uint averageTokenPriceForPurchase = inputUSD.mul(10**18).div(totalTokensBought);

        // check if contract is first time interacting with this one
        uint contractId = getContractId(msg.sender);

        // Check if the contract exists
        if(contractId == 0) {
            contractId = addNewContract(msg.sender);
        }

        setHedgingInformationAndContractStats(
            contractId,
            totalTokensBought,
            value
        );

        _processPurchase(_beneficiary, totalTokensBought);

        return (totalTokensBought, averageTokenPriceForPurchase);
    }

    function buyTokensWithERC20(
        uint amountOfTokens,
        address tokenAddress
    )
    public
    returns (uint,uint)
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));

        // Increment amount of this stable tokens to fill reserve
        addStableCoinsAvailableToFillReserve(amountOfTokens, tokenAddress);

        // Compute the exact amount in $
        uint amountInUSDOfPurchase = computeAmountInUsd(amountOfTokens, tokenAddress);

        // Create path to go through WETH
        address [] memory path = new address[](3);

        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        // The path is WETH -> 2KEY
        path[0] = tokenAddress;
        path[1] = IUniswapV2Router02(uniswapRouter).WETH();
        path[2] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");


        // Get amount of tokens receiving
        uint totalTokensBought = buyRate2Key(
            uniswapRouter,
            amountOfTokens,
            path
        );

        // Compute what is the average price for the purchase
        uint averageTokenPriceForPurchase = amountInUSDOfPurchase.mul(10**18).div(totalTokensBought);

        // Transfer tokens
        _processPurchase(msg.sender, totalTokensBought);

        // Return amount of tokens received and average token price for purchase
        return (totalTokensBought, averageTokenPriceForPurchase);
    }


    function computeAmountInUsd(
        uint amountInTokenDecimals,
        address tokenAddress
    )
    internal
    view
    returns (uint)
    {
        // Get the address of twoKeyExchangeRateContract
        address twoKeyExchangeRateContract = getAddressFromTwoKeySingletonRegistry(_twoKeyExchangeRateContract);

        // Get stable coin to dollar rate
        uint tokenToUsd = ITwoKeyExchangeRateContract(twoKeyExchangeRateContract).getStableCoinToUSDQuota(tokenAddress);

        // Get token decimals
        uint tokenDecimals = IERC20(tokenAddress).decimals();

        uint oneEth = 10 ** 18;

        return amountInTokenDecimals.mul(oneEth.div(10 ** tokenDecimals)).mul(tokenToUsd).div(oneEth);
    }



    /**
     * @notice          Internal function to update the state in case tokens were bought for influencers
     *yes
     * @param           contractID is the ID of the contract
     * @param           amountOfTokensBeingSentToContract is the amount of 2KEY tokens being sent to the contract
     * @param           purchaseAmountETH is the amount of ETH spent to purchase tokens
     */
    function setHedgingInformationAndContractStats(
        uint contractID,
        uint amountOfTokensBeingSentToContract,
        uint purchaseAmountETH
    )
    internal
    {
        // Update how much ether we received from msg.sender contract
        bytes32 ethReceivedFromContractKeyHash = keccak256("ethReceivedFromContract", contractID);
        setUint(ethReceivedFromContractKeyHash, ethReceivedFromContract(contractID).add(purchaseAmountETH));

        // Update how much 2KEY tokens we sent to msg.sender contract
        bytes32 sent2keyToContractKeyHash = keccak256("sent2keyToContract", contractID);
        setUint(sent2keyToContractKeyHash, sent2keyToContract(contractID).add(amountOfTokensBeingSentToContract));

        updateEthWeiAvailableToHedge(contractID, purchaseAmountETH);

    }


    function setStableCoinsAvailableToFillReserve(
        uint amountOfStableCoins,
        address stableCoinAddress
    )
    internal
    {
        bytes32 key = keccak256("stableCoinToAmountAvailableToFillReserve", stableCoinAddress);

        setUint(
            key,
            amountOfStableCoins
        );
    }


    function addStableCoinsAvailableToFillReserve(
        uint amountOfStableCoins,
        address stableCoinAddress
    )
    internal
    {
        bytes32 key = keccak256("stableCoinToAmountAvailableToFillReserve", stableCoinAddress);

        uint currentBalance = getUint(key);
        setUint(
            key,
            currentBalance.add(amountOfStableCoins)
        );
    }

    function getAvailableAmountToFillReserveInternal(
        address tokenAddress
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("stableCoinToAmountAvailableToFillReserve", tokenAddress));
    }

    /**
     * @notice          Function to get array containing how much of the tokens are available to fill reserve
     * @param           stableCoinAddresses is array of stable coin
     */
    function getAvailableAmountToFillReserve(
        address [] stableCoinAddresses
    )
    public
    view
    returns (uint[])
    {
        uint numberOfTokens = stableCoinAddresses.length;
        uint[] memory availableAmounts = new uint[](numberOfTokens);

        uint i;
        for(i=0; i<numberOfTokens; i++) {
            availableAmounts[i] = getAvailableAmountToFillReserveInternal(stableCoinAddresses[i]);
        }

        return availableAmounts;
    }


    function releaseAllDAIFromContractToReserve()
    public
    onlyValidatedContracts
    {
        uint _contractID = getContractId(msg.sender);
        bytes32 _daiWeiAvailableToWithdrawKeyHash = keccak256("daiWeiAvailableToWithdraw",_contractID);
        bytes32 _daiWeiAvailableToFill2KEYReserveKeyHash = keccak256("daiWeiAvailableToFill2KEYReserve");

        uint _daiWeiAvailableToWithdrawAndFillReserve = daiWeiAvailableToWithdraw(_contractID);

        uint _daiWeiAvailableToFill2keyReserveCurrently = daiWeiAvailableToFill2KEYReserve();

        setUint(_daiWeiAvailableToFill2KEYReserveKeyHash, _daiWeiAvailableToFill2keyReserveCurrently.add(_daiWeiAvailableToWithdrawAndFillReserve));
        setUint(_daiWeiAvailableToWithdrawKeyHash, 0);

        // Emit the event that DAI is released
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitDAIReleasedAsIncome(
            msg.sender,
            _daiWeiAvailableToWithdrawAndFillReserve
        );

    }

    /**
     * @notice          Function which will be called every time by campaign when referrer select to withdraw directly 2key token
     *
     * @param           amountOfTokensWithdrawn is the amount of tokens he wants to withdraw
     */
    function report2KEYWithdrawnFromNetwork(
        uint amountOfTokensWithdrawn
    )
    public
    onlyValidatedContracts
    {
        uint _contractID = getContractId(msg.sender);
        if(ethReceivedFromContract(_contractID) > 0 ) {
            report2KEYWithdrawnFromNetworkInternal(amountOfTokensWithdrawn, _contractID);
        }
    }


    /**
     * @notice          Function to get expected rate from Kyber contract
     * @param           amountSrcWei is the amount we'd like to exchange
     * @param           srcToken is the address of src token we want to swap
     * @param           destToken is the address of destination token we want to get
     * @return          if the value is 0 that means we can't
     */
    function getKyberExpectedRate(
        uint amountSrcWei,
        address srcToken,
        address destToken
    )
    public
    view
    returns (uint)
    {
        address kyberProxyContract = getAddress(keccak256(_kyberNetworkProxy));
        IKyberNetworkProxy proxyContract = IKyberNetworkProxy(kyberProxyContract);

        ERC20 src = ERC20(srcToken);
        ERC20 dest = ERC20(destToken);

        uint minConversionRate;
        (minConversionRate,) = proxyContract.getExpectedRate(src, dest, amountSrcWei);

        return minConversionRate;
    }


    /**
     * @notice          Function to relay demand of stable coins we have in exchange to
     *                  uniswap exchange.
     * @param           stableCoinsAddresses is array of addresses of stable coins we're going to swap
     * @param           amounts are corresponding amounts of tokens that are going to be swapped.
     */
    function swapStableCoinsAvailableToFillReserveFor2KEY(
        address [] stableCoinsAddresses,
        uint [] amounts
    )
    public
    onlyMaintainer
    {
        uint numberOfTokens = stableCoinsAddresses.length;
        uint i;

        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        // Create a path array
        address [] memory path = new address[](3);

        for (i = 0; i < numberOfTokens; i++) {
            // Load the token address
            address tokenAddress = stableCoinsAddresses[i];

            // Get how much is available to fill reserve
            uint availableForReserve = getAvailableAmountToFillReserveInternal(tokenAddress);

            // Require that amount wanted to swap is less or equal to amount present in reserve
            require(amounts[i] <= availableForReserve);

            uint amountToSwap = amounts[i];

            // Reduce amount used to swap from available in reserve
            setStableCoinsAvailableToFillReserve(
                availableForReserve.sub(amountToSwap),
                tokenAddress
            );

            // Approve uniswap router to take tokens from the contract
            IERC20(tokenAddress).approve(
                uniswapRouter,
                amountToSwap
            );

            // Override always the path array
            path[0] = tokenAddress;
            path[1] = IUniswapV2Router02(uniswapRouter).WETH();
            path[2] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");

            // Get minimum received
            uint minimumToReceive = uniswapPriceDiscoverForBuyingFromUniswap(
                uniswapRouter,
                amountToSwap,
                path
            );

            // Execute swap
            IUniswapV2Router01(uniswapRouter).swapExactTokensForTokens(
                amountToSwap,
                minimumToReceive.mul(97).div(100), // Allow 3 percent to drop
                path,
                address(this),
                block.timestamp + (10 minutes)
            );
        }
    }


    /**
     * @notice          Function to start hedging some ether amount
     * @param           amountToBeHedged is the amount we'd like to hedge
     * @dev             only maintainer can call this function
     */
    function startHedging(
        uint amountToBeHedged,
        uint approvedMinConversionRate
    )
    public
    onlyMaintainer
    {
        ERC20 dai = ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI"));

        if(amountToBeHedged > address(this).balance) {
            amountToBeHedged = address(this).balance;
        }

        address kyberProxyContract = getAddress(keccak256(_kyberNetworkProxy));
        IKyberNetworkProxy proxyContract = IKyberNetworkProxy(kyberProxyContract);

        // Get minimal conversion rate for the swap of ETH->DAI token
        uint minConversionRate = getKyberExpectedRate(amountToBeHedged, ETH_TOKEN_ADDRESS, address(dai));

        require(minConversionRate >= approvedMinConversionRate.mul(95).div(100)); //Means our rate can be at most same as their rate, because they're giving the best rate
        uint stableCoinUnits = proxyContract.swapEtherToToken.value(amountToBeHedged)(dai,minConversionRate);
        // Get the ratio between ETH and DAI for this hedging
        uint ratio = calculateRatioBetweenDAIandETH(amountToBeHedged, stableCoinUnits);
        //Emit event with important data
        emit HedgedEther(stableCoinUnits, ratio, numberOfContracts());
    }


    function calculateHedgedAndReceivedForDefinedChunk(
        uint numberOfContractsCurrently,
        uint amountHedged,
        uint stableCoinsReceived,
        uint startIndex,
        uint endIndex
    )
    public
    view
    returns (uint,uint)
    {
        //We're calculating sum on contracts between start and end index
        uint sumInRange = calculateSumOnContracts(startIndex,endIndex);
        //Now we need how much was hedged from this contracts between start and end index
        uint stableCoinsReceivedForThisChunkOfContracts = (sumInRange.mul(stableCoinsReceived)).div(amountHedged);
        // Returning for this piece of contracts
        return (sumInRange, stableCoinsReceivedForThisChunkOfContracts);
    }

    /**
     * @notice          Function to reduce available amount to hedge and increase available DAI to withdraw
     *
     * @param           _ethWeiHedgedForThisChunk is how much eth was hedged
     * @param           _daiReceivedForThisChunk is how much DAI's we got for that hedging
     */
    function reduceHedgedAmountFromContractsAndIncreaseDaiAvailable(
        uint _ethWeiHedgedForThisChunk,
        uint _daiReceivedForThisChunk,
        uint _ratio,
        uint _startIndex,
        uint _endIndex
    )
    public
    onlyMaintainer
    {
        uint i;
        uint percentageToDeductWei = calculatePercentageToDeduct(_ethWeiHedgedForThisChunk, _ethWeiHedgedForThisChunk); // Percentage to deduct in WEI (less than 1)
        address twoKeyFactory = getAddressFromTwoKeySingletonRegistry("TwoKeyFactory");
        for(i=_startIndex; i<=_endIndex; i++) {
            if(ethWeiAvailableToHedge(i) > 0) {
                uint beforeHedgingAvailableEthWeiForContract = ethWeiAvailableToHedge(i);
                uint hundredPercentWei = 10**18;
                uint afterHedgingAvailableEthWei = beforeHedgingAvailableEthWeiForContract.mul(hundredPercentWei.sub(percentageToDeductWei)).div(10**18);

                uint hedgedEthWei = beforeHedgingAvailableEthWeiForContract.sub(afterHedgingAvailableEthWei);
                uint daisReceived = hedgedEthWei.mul(_ratio).div(10**18);
                updateWithdrawOrReservePoolDependingOnCampaignType(i, daisReceived, twoKeyFactory);
                updateAccountingValues(daisReceived, hedgedEthWei, afterHedgingAvailableEthWei, i);
            }
        }
    }


    /**
     * @notice          Function which will be called by 2key campaigns if user wants to withdraw his earnings in stableCoins
     *
     * @param           _twoKeyUnits is the amount of 2key tokens which will be taken from campaign
     * @param           _beneficiary is the user who will receive the tokens
     */
    function buyStableCoinWith2key(
        uint _twoKeyUnits,
        address _beneficiary
    )
    public
    onlyValidatedContracts
    {
        ERC20 dai = ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI"));
        ERC20 token = ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy));

        uint contractId = getContractId(msg.sender); // Get the contract ID

        uint stableCoinUnits = getUSDStableCoinAmountFrom2keyUnits(_twoKeyUnits, contractId); // Calculate how much stable coins he's getting
        uint etherBalanceOnContractBefore = this.balance; // get ether balance on contract
        uint stableCoinsOnContractBefore = dai.balanceOf(address(this)); // get dai balance on contract

        reduceDaiWeiAvailableToWithdraw(msg.sender, stableCoinUnits); // reducing amount of DAI available for withdrawal

        emitEventWithdrawExecuted(
            _beneficiary,
            stableCoinsOnContractBefore,
            stableCoinsOnContractBefore.sub(stableCoinUnits),
            etherBalanceOnContractBefore,
            stableCoinUnits,
            _twoKeyUnits
        );

        token.transferFrom(msg.sender, address(this), _twoKeyUnits); //Take all 2key tokens from campaign contract
        payFeesToManagerAndTransferTokens(_beneficiary, contractId, stableCoinUnits, dai);
    }


    /**
     * @notice          Function to return number of campaign contracts (different) interacted with this contract
     */
    function numberOfContracts()
    public
    view
    returns (uint)
    {
        return getUint(keccak256("numberOfContracts"));
    }


    /**
     * @notice          Function to get 2key to DAI hedged rate
     *
     * @param           _contractID is the ID of the contract we're fetching this rate (avg)
     */
    function get2KEY2DAIHedgedRate(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        return getEth2DaiAverageExchangeRatePerContract(_contractID).mul(10**18).div(getEth2KeyAverageRatePerContract(_contractID));
    }

    /**
     * @notice          Function to get Eth2DAI average exchange rate per contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
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
        return daiWeiReceivedFromHedgingPerContractByNow.mul(10**18).div(ethWeiHedgedPerContractByNow); //dai/eth
    }


    /**
     * @notice          Function to get Eth22key average exchange rate per contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
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
        if(sent2keyToContractByNow == 0 || ethReceivedFromContractByNow == 0) {
            return 0;
        }
        // Average weighted by eth 2key/eth
        return sent2keyToContractByNow.mul(10**18).div(ethReceivedFromContractByNow);
    }


    /**
     * @notice          Function to check how much dai is available to fill reserve
     */
    function daiWeiAvailableToFill2KEYReserve()
    public
    view
    returns (uint)
    {
        return getUint(keccak256("daiWeiAvailableToFill2KEYReserve"));
    }


    /**
     * @notice          Getter for mapping "daiWeiAvailableToWithdraw" (per contract)
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
     * @notice          Getter for "mapping" ethWeiAvailableToHedge (per contract)
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
     * @notice          Getter wrapping all information about income/outcome for every contract
     * @param           _contractAddress is the main campaign address
     */
    function getAllStatsForContract(
        address _contractAddress
    )
    public
    view
    returns (uint,uint,uint,uint,uint,uint)
    {
        uint _contractID = getContractId(_contractAddress);
        return (
            ethWeiAvailableToHedge(_contractID),
            daiWeiAvailableToWithdraw(_contractID),
            daiWeiReceivedFromHedgingPerContract(_contractID),
            ethWeiHedgedPerContract(_contractID),
            sent2keyToContract(_contractID),
            ethReceivedFromContract(_contractID)
        );
    }


    /**
     * @notice          Getter function to check if campaign has been hedged ever
     *                  Assuming that this function regarding flow will be called at point where there must be
     *                  executed conversions, and in that case, if there are no any ETH received from contract,
     *                  that means that this campaign is not hedgeable
     *
     * @param           _contractAddress is the campaign address
     */
    function isCampaignHedgeable(
        address _contractAddress
    )
    public
    view
    returns (bool)
    {
        uint _contractID = getContractId(_contractAddress);
        return ethReceivedFromContract(_contractID) > 0 ? true : false;
    }


    /**
     * @notice          Function to get contract address from it's ID
     * @param           contractID is the ID assigned to contract
     */
    function getContractAddressFromID(
        uint contractID
    )
    internal
    view
    returns (address)
    {
        return getAddress(keccak256("idToContractAddress", contractID));
    }


    /**
     * @notice          Getter to get spreadWei value
     */
    function spreadWei()
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("spreadWei"));
    }

    /**
     * @notice          Represents current 2KEY sell rate, and is used only for informative purpose
     *                  This function shouldn't be included into any buy/sell orders, since it's
     *                  just checking what is current average rate, not including price discovery for
     *                  bigger amounts
     */
    function sellRate2key()
    public
    view
    returns (uint)
    {
        // Fetch rate for 1 2KEY token
        return sellRate2KeyInternal(10 ** 18);
    }

    function sellRate2KeyInternal(
        uint amountToReceive
    )
    internal
    view
    returns (uint)
    {
        address twoKeyExchangeRateContract = getAddressFromTwoKeySingletonRegistry(_twoKeyExchangeRateContract);

        address [] memory path = new address[](2);
        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        // The path is WETH -> 2KEY
        path[0] = IUniswapV2Router02(uniswapRouter).WETH();
        path[1] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");

        // Represents how much ETH user has to put in order to get amountToReceive 2KEY token
        uint rateFromUniswap = uniswapPriceDiscover(uniswapRouter, amountToReceive, path);

        // Rate from ETH-USD oracle
        uint eth_usdRate = ITwoKeyExchangeRateContract(getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract"))
        .getBaseToTargetRate("USD");

        // Return rate which will represent how many USD has to be put in for amountToReceive 2KEY tokens
        return rateFromUniswap.mul(eth_usdRate).div(10**18);
    }


    function buyRate2Key(
        address uniswapRouter,
        uint input,
        address [] path
    )
    public
    view
    returns (uint)
    {
        // Represents how much 2KEY's user gets for input in ETH
        return uniswapPriceDiscoverForBuyingFromUniswap(uniswapRouter, input, path);
    }


    function withdrawDAIAvailableToFill2KEYReserve(
        uint amountOfDAI
    )
    public
    onlyTwoKeyAdmin
    returns (uint)
    {
        uint daiWeiAvailableToFill2keyReserve = daiWeiAvailableToFill2KEYReserve();
        if(amountOfDAI == 0) {
            amountOfDAI = daiWeiAvailableToFill2keyReserve;
        } else {
            require(amountOfDAI <= daiWeiAvailableToFill2keyReserve);
        }

        ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI")).transfer(msg.sender, amountOfDAI);
        bytes32 key = keccak256("daiWeiAvailableToFill2KEYReserve");

        // Set that there's not DAI to fill reserve anymore
        setUint(key, daiWeiAvailableToFill2keyReserve.sub(amountOfDAI));

        // Return how much have been withdrawn
        return amountOfDAI;
    }


    /**
     * @notice          Function to be used to fetch rates for SELL orders
     * @notice          amountToReceive is desired amount of 2KEY tokens to be received
     * @param           path is the path of swap (TOKEN_A - TOKEN_B) or (TOKEN_A - WETH - TOKEN_B)
     */
    function uniswapPriceDiscover(
        address uniswapRouter,
        uint amountToReceive,
        address [] path
    )
    public
    view
    returns (uint)
    {
        uint[] memory amountsIn = new uint[](2);

        amountsIn = IUniswapV2Router02(uniswapRouter).getAmountsIn(
            amountToReceive,
            path
        );

        return amountsIn[0];
    }

    /**
     * @notice          Function to be used to fetch rates from uniswap assuming there's a buy order
     * @notice          amountToSwap is in wei value
     * @param           path is the path of swap (TOKEN_A - TOKEN_B) or (TOKEN_A - WETH - TOKEN_B)
     */
    function uniswapPriceDiscoverForBuyingFromUniswap(
        address uniswapRouter,
        uint amountToSwap,
        address [] path
    )
    public
    view
    returns (uint)
    {
        uint[] memory amountsOut = new uint[](2);

        amountsOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(
            amountToSwap,
            path
        );

        return amountsOut[1];
    }


    /**
     * @notice          Fallback function to handle incoming ether
     */
    function()
    public
    payable
    {

    }

}
