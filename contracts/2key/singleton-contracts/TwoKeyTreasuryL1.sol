pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITether.sol";
import "../libraries/Call.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/storage-contracts/ITwoKeyTreasuryL1Storage.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/ITwoKeyRegistry.sol";
import "../interfaces/ITwoKeyPlasmaAccountManager.sol";
import "../interfaces/IUpgradableExchange.sol";

/**
 * TwoKeyTreasuryL1 contract receiving all deposits from contractors.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract TwoKeyTreasuryL1 is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for *;
    using Call for *;

    string constant _isExistingSignature = "isExistingSignature";
    string constant _messageNotes = "binding rewards for user";
    string constant _tokenAddress = "tokenAddress";


    bool initialized;

    ITwoKeyTreasuryL1Storage public PROXY_STORAGE_CONTRACT;

    mapping(address => mapping(address => uint)) public userTokenDepositAmount;  // user => token => amount
    mapping(address => uint) public userETHDepositAmount;    // user => amount
    mapping(address => uint) public userUSDDepositBalance; // user => amount
    mapping(address => uint) public userUSDWithdrawBalance;   // user => amount
    mapping(address => uint) public user2KEYWithdrawBalance;   // user => amount

    event Deposit2KEY(address indexed depositor, uint amount);
    event DepositStableCoin(address indexed depositor, uint amount);
    event DepositVolatileToken(address indexed depositor, address indexed fromTokenAddress, uint fromAmount, address toTokenAddress, uint toTokenAmount, uint buyRate);
    event DepositETH(address indexed depositor, uint amount, address toTokenAddress, uint toTokenAmount, uint daiBuyRate);
    event WithdrawToken(address indexed beneficiary, address indexed token, uint amount);



    function setInitialParams(
        address twoKeySingletonesRegistry,
        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyTreasuryL1Storage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice          Fallback function to handle deposits in ether
     */
    function()
    public
    payable
    {
        depositETH(msg.sender, msg.value);
    }

    /**
     * @notice Set the avaialble token addresses
     * @param tokenName is the token name
     * @param tokenAddress is the token address
     */
    function setTokenAddress(
        string tokenName,
        address tokenAddress
    )
    public
    onlyMaintainer
    {
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(tokenName), tokenAddress);
    }

    /**
     * @notice Get the token address
     * @param tokenName is the token name
     * @return (address) is the token address
     */
    function getTokenAddress(
        string tokenName
    )
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(tokenName));
    }

    /**
     * @notice          Function to return who signed msg
     * @param           campaignPlasma is the plasma address of the campaign
     * @param           amountOfTokens is the amount of pending rewards user wants to claim
     * @param           buy2keyRateL2 is the 2key rate sent by maintainer
     * @param           signature is the signature created by maintainer
     */
    function recoverSignatureForModeratorUSD(
        address campaignPlasma,
        uint amountOfTokens,
        uint buy2keyRateL2,
        bytes signature
    )
    public
    view
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(_messageNotes)),
                keccak256(abi.encodePacked(campaignPlasma, amountOfTokens, buy2keyRateL2))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash, signature, 0);
    }

    /**
     * @notice          Function to return who signed msg
     * @param           campaignPlasma is the plasma address of the campaign
     * @param           amountOfTokens is the amount of pending rewards user wants to claim
     * @param           signature is the signature created by maintainer
     */
    function recoverSignatureForModerator2KEY(
        address campaignPlasma,
        uint amountOfTokens,
        bytes signature
    )
    public
    view
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(_messageNotes)),
                keccak256(abi.encodePacked(campaignPlasma, amountOfTokens))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash,signature,0);
    }

    /**
     * @notice          Function to return who signed msg
     * @param           amountOfTokens is the amount of pending rewards user wants to claim
     * @param           buy2keyRateL2 is the 2key rate sent by maintainer
     * @param           signature is the signature created by maintainer
     */
    function recoverSignatureForReferrerUSD(
        address beneficiary,
        uint amountOfTokens,
        uint buy2keyRateL2,
        bytes signature
    )
    public
    view
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(_messageNotes)),
                keccak256(abi.encodePacked(beneficiary, amountOfTokens, buy2keyRateL2))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash, signature, 0);
    }

    /**
     * @notice          Function to return who signed msg
     * @param           amountOfTokens is the amount of pending rewards user wants to claim
     * @param           signature is the signature created by maintainer
     */
    function recoverSignatureForReferrer2KEY(
        address beneficiary,
        uint amountOfTokens,
        bytes signature
    )
    public
    view
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(_messageNotes)),
                keccak256(abi.encodePacked(beneficiary, amountOfTokens))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash,signature,0);
    }

    /**
     * @notice          Function to deposit 2KEY token
     * @param           token is the address of the token being deposited
     * @param           amount is the amount of token to deposit
     */
    function deposit2KEY(
        address token,
        uint amount
    )
    public
    {
        require(token != address(0), "TwoKeyTreasuryL1: Invalid token address");
        require(token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy"), "TwoKeyTreasuryL1: Not 2Key token");
        require(amount > 0, "TwoKeyTreasuryL1: Token amount to deposit must be greater than zero");
        
        require(amount <= IERC20(token).allowance(msg.sender, address(this)));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount));

        userTokenDepositAmount[msg.sender][token] = userTokenDepositAmount[msg.sender][token].add(amount);

        emit Deposit2KEY(msg.sender, amount);
    }

    /**
     * @notice          Function to deposit stable coins - BUSD/USDC/TUSD/PAX/DAI
     * @param           token is the address of the token being deposited
     * @param           amount is the amount of token to deposit
     */
    function depositStableCoin(
        address token,
        uint amount
    )
    public
    {
        require(token != address(0), "TwoKeyTreasuryL1: Invalid token address");
        require(amount > 0, "TwoKeyTreasuryL1: Token amount to deposit must be greater than zero");

        if (token == getTokenAddress("BUSD") ||
            token == getTokenAddress("TUSD") ||
            token == getTokenAddress("PAX") ||
            token == getTokenAddress("DAI") ||
            token == getTokenAddress("USDC")
        ) {
            require(amount <= IERC20(token).allowance(msg.sender, address(this)));
            require(IERC20(token).transferFrom(mfvsg.sender, address(this), amount));

            // adjust the decimals
            if (token == getTokenAddress("USDC")) {
                amount = amount.mul(10**12);
            }

            userTokenDepositAmount[msg.sender][token] = userTokenDepositAmount[msg.sender][token].add(amount);
            userUSDDepositBalance[msg.sender] = userUSDDepositBalance[msg.sender].add(amount);
    
            emit DepositStableCoin(msg.sender, amount);

        } else if (token == getTokenAddress("USDT")) {
            require(amount <= ITether(token).allowance(msg.sender, address(this)));
            ITether(token).transferFrom(msg.sender, address(this), amount);

            // adjust the decimals
            amount = amount.mul(10**12);

            userTokenDepositAmount[msg.sender][token] = userTokenDepositAmount[msg.sender][token].add(amount);
            userUSDDepositBalance[msg.sender] = userUSDDepositBalance[msg.sender].add(amount);

            emit DepositStableCoin(msg.sender, amount);
        }
    }

    /**
     * @notice          Function to deposit non 2key/stable coins - RENBTC/WBTC/WETH
     * @param           token is the address of the token being deposited
     * @param           amount is the amount of token to deposit
     */
    function depositVolatileToken(
        address token,
        uint amount
    )
    public
    {
        require(token != address(0), "TwoKeyTreasuryL1: Invalid token address");
        require(amount > 0, "TwoKeyTreasuryL1: Token amount to deposit must be greater than zero");

        if (token == getTokenAddress("RENBTC") ||
            token == getTokenAddress("WBTC") ||
            token == getTokenAddress("WETH")
        ) {
            require(amount <= IERC20(token).allowance(msg.sender, address(this)));
            require(IERC20(token).transferFrom(msg.sender, address(this), amount));

            (uint daiAmount, uint daiBuyRate) = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).simulateBuyStableCoinWithERC20(amount, token);

            userTokenDepositAmount[msg.sender][token] = userTokenDepositAmount[msg.sender][token].add(amount);
            userUSDDepositBalance[msg.sender] = userUSDDepositBalance[msg.sender].add(daiAmount);
    
            emit DepositVolatileToken(msg.sender, token, amount, getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI"), daiAmount, daiBuyRate);
        }
    }

    /**
     * @notice          Function to deposit non 2key/stable coins - RENBTC/WBTC/WETH
     * @param           userAddress is the address of the token being deposited
     * @param           amount is the amount of token to deposit
     */
    function depositETH(
        address userAddress,
        uint amount
    )
    internal
    {
        require(amount > 0, "TwoKeyTreasuryL1: Token amount to deposit must be greater than zero");

        (uint daiAmount, uint daiBuyRate) = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).simulateBuyStableCoinWithETH(amount);

        userETHDepositAmount[msg.sender] = userETHDepositAmount[msg.sender].add(amount);
        userUSDDepositBalance[msg.sender] = userUSDDepositBalance[msg.sender].add(daiAmount);

        emit DepositETH(userAddress, amount, getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI"), daiAmount, daiBuyRate);
    }

    /**
     * @notice          Function to withdraw moderator USD balance
     * @param           campaignPlasma is the plasma address of the campaign to withdraw moderator earnings
     * @param           amount is USD amount
     * @param           buy2keyRateL2 is the 2key price set by maintainer
     * @param           signature is proof that beneficiary has amount of tokens he wants to withdraw
     */
    function withdrawModeratorBalanceUSD(
        address campaignPlasma,
        uint amount,
        uint buy2keyRateL2,
        bytes signature
    )
    public
    onlyMaintainer
    {
        bytes32 key = keccak256(_isExistingSignature, signature);
        // Require that signature doesn't exist
        require(PROXY_STORAGE_CONTRACT.getBool(key) == false);
        // Set that this signature is used and exists
        PROXY_STORAGE_CONTRACT.setBool(key, true);
        // Check who signed the message
        address messageSigner = recoverSignatureForModeratorUSD(campaignPlasma, amount, buy2keyRateL2, signature);
        // Get the instance of TwoKeyRegistry
        ITwoKeyRegistry registry = ITwoKeyRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));
        // Assert that this signature is created by signatory address
        require(messageSigner == registry.getSignatoryAddress());

        address beneficiary = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        
        uint withdrawBalanceUSD;
        uint withdrawBalance2KEY;

        // Get the current 2key buy rate
        uint uniswap2keyRate = getUniswap2KeyBuyPriceInUSD();

        // Allow 10% change of the price
        require(uniswap2keyRate >= buy2keyRateL2.mul(9).div(10), "TwoKeyTreasuryL1: Invalid 2key price");
        require(uniswap2keyRate <= buy2keyRateL2.mul(11).div(10), "TwoKeyTreasuryL1: Invalid 2key price");

        withdrawBalanceUSD = amount;
        withdrawBalance2KEY = amount.div(buy2keyRateL2).mul(10**18);

        userUSDWithdrawBalance[beneficiary] = userUSDWithdrawBalance[beneficiary].add(withdrawBalanceUSD);


        // Get the instance of 2KEY token contract
        IERC20 twoKeyEconomy = IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy"));
        // Transfer tokens to the user
        twoKeyEconomy.transfer(beneficiary, withdrawBalance2KEY);

        // Update moderator on received tokens so it can proceed distribution to TwoKeyDeepFreezeTokenPool
        ITwoKeyAdmin(twoKeyAdmin).updateReceivedTokensAsModeratorPPC(withdrawBalance2KEY, campaignPlasma);

        emit WithdrawToken(beneficiary, address(twoKeyEconomy), withdrawBalance2KEY);

    }

    /**
     * @notice          Function to withdraw moderator 2KEY balance
     * @param           campaignPlasma is the plasma address of the campaign to withdraw moderator earnings
     * @param           amount is the amount of tokens to withdraw
     * @param           signature is proof that beneficiary has amount of tokens he wants to withdraw
     */
    function withdrawModeratorBalance2KEY(
        address campaignPlasma,
        uint amount,
        bytes signature,
    )
    public
    onlyMaintainer
    {
        bytes32 key = keccak256(_isExistingSignature, signature);
        // Require that signature doesn't exist
        require(PROXY_STORAGE_CONTRACT.getBool(key) == false);
        // Set that this signature is used and exists
        PROXY_STORAGE_CONTRACT.setBool(key, true);
        // Check who signed the message
        address messageSigner = recoverSignatureForModerator2KEY(campaignPlasma, amount, signature);
        // Get the instance of TwoKeyRegistry
        ITwoKeyRegistry registry = ITwoKeyRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));
        // Assert that this signature is created by signatory address
        require(messageSigner == registry.getSignatoryAddress());

        address beneficiary = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");


        uint withdrawBalance2KEY;      
        
        withdrawBalance2KEY = amount;
        user2KEYWithdrawBalance[beneficiary] = user2KEYWithdrawBalance[beneficiary].add(withdrawBalance2KEY);

        // Get the instance of 2KEY token contract
        IERC20 twoKeyEconomy = IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy"));
        // Transfer tokens to the user
        twoKeyEconomy.transfer(beneficiary, withdrawBalance2KEY);

        emit WithdrawToken(beneficiary, address(twoKeyEconomy), withdrawBalance2KEY);
    }

    /**
     * @notice          Function to withdraw ERC20 token
     * @param           beneficiary is the user to withdraw token
     * @param           amount is the amount of tokens to withdraw
     * @param           buy2keyRateL2 is the 2key price set by maintainer
     * @param           signature is proof that maintainer is the message signer
     */
    function withdrawReferrerBalanceUSD( //TODO: rename to withdrawL2BalanceUSD
        address beneficiary,
        uint amount,
        uint buy2keyRateL2, //TODO: maintainer should call this in current rate
        bytes signature
    )
    public
    onlyMaintainer //TODO should not be called by maintainer , should be called by users
    {
        bytes32 key = keccak256(_isExistingSignature, signature);
        // Require that signature doesn't exist
        require(PROXY_STORAGE_CONTRACT.getBool(key) == false);
        // Set that this signature is used and exists
        PROXY_STORAGE_CONTRACT.setBool(key, true);
        // Check who signed the message
        address messageSigner = recoverSignatureForReferrerUSD(beneficiary, amount, buy2keyRateL2, signature);
        // Get the instance of TwoKeyRegistry
        ITwoKeyRegistry registry = ITwoKeyRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));
        // Assert that this signature is created by signatory address
        require(messageSigner == registry.getSignatoryAddress());
        //TODO require that beneficiary is msg.sender
        twoKeyTokenAddress = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");

        //TODO: get current rate for amount USD to 2KEY from uniswap, and make sure that there is no more than 5% drift from the maintainer provided rate.

        uint withdrawBalanceUSD;
        uint withdrawBalance2KEY;

        // Get the current 2key buy rate
        uint uniswap2keyRate = getUniswap2KeyBuyPriceInUSD();

        // Allow 10% change of the price
        require(uniswap2keyRate >= buy2keyRateL2.mul(9).div(10), "TwoKeyTreasuryL1: Invalid 2key price");
        require(uniswap2keyRate <= buy2keyRateL2.mul(11).div(10), "TwoKeyTreasuryL1: Invalid 2key price");

        withdrawBalanceUSD = amount;
        withdrawBalance2KEY = amount.div(buy2keyRateL2).mul(10**18);
        // safeguard
        require(withdrawBalanceUSD <= userUSDDepositBalance[beneficiary].sub(userUSDWithdrawBalance[beneficiary]), "TwoKeyTreasuryL1: Exceeds witdraw amount");

        userUSDWithdrawBalance[beneficiary] = userUSDWithdrawBalance[beneficiary].add(withdrawBalanceUSD);
        

        // Get the instance of 2KEY token contract
        IERC20 twoKeyEconomy = IERC20(twoKeyTokenAddress);
        // Transfer tokens to the user
        twoKeyEconomy.transfer(beneficiary, withdrawBalance2KEY);

        emit WithdrawToken(beneficiary, address(twoKeyEconomy), withdrawBalance2KEY);
    }

    /**
     * @notice          Function to withdraw ERC20 token
     * @param           beneficiary is the user to withdraw token
     * @param           amount is the amount of tokens to withdraw
     * @param           signature is proof that maintainer is the message signer
     */
    function withdrawReferrerBalance2KEY(
        address beneficiary, //TODO remove this, the msg.sender is the beneficiary
        uint amount,
        bytes signature
    )
    public
    //TODO: make this public, anyone can call
    onlyMaintainer
    {
        bytes32 key = keccak256(_isExistingSignature, signature);
        // Require that signature doesn't exist
        require(PROXY_STORAGE_CONTRACT.getBool(key) == false);
        // Set that this signature is used and exists
        PROXY_STORAGE_CONTRACT.setBool(key, true);
        // Check who signed the message
        address messageSigner = recoverSignatureForReferrer2KEY(beneficiary, amount, signature);
        // Get the instance of TwoKeyRegistry
        ITwoKeyRegistry registry = ITwoKeyRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));
        // Assert that this signature is created by signatory address
        require(messageSigner == registry.getSignatoryAddress());
    
        twoKeyTokenAddress = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");


        uint withdrawBalance2KEY;
        
        uint withdrawBalance2KEY = amount;
        // safeguard
        //TODO: modify safeguard to make sure the withdrawn amount is not worth more than the non-2KEY usd worth on contract, and we'll put some safeguards on maximal withdraw per day
        require(withdrawBalance2KEY <= userTokenDepositAmount[beneficiary][twoKeyTokenAddress].sub(user2KEYWithdrawBalance[beneficiary]), "TwoKeyTreasuryL1: Exceeds witdraw amount");

        user2KEYWithdrawBalance[beneficiary] = user2KEYWithdrawBalance[beneficiary].add(withdrawBalance2KEY);
        

        // Get the instance of 2KEY token contract
        IERC20 twoKeyEconomy = IERC20(twoKeyTokenAddress);
        // Transfer tokens to the user
        twoKeyEconomy.transfer(beneficiary, withdrawBalance2KEY);

        emit WithdrawToken(beneficiary, address(twoKeyEconomy), withdrawBalance2KEY);
    }

    function getUniswap2KeyBuyPriceInUSD()
    internal
    returns (uint256) {
        address [] memory path = new address[](3);

        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        path[0] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI");
        path[1] = IUniswapV2Router02(uniswapRouter).WETH();
        path[2] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");

        uint totalTokensBought = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).buyRate2key(
            uniswapRouter,
            10**18, // 1 DAI
            path
        );

        return totalTokensBought;
    }

    /**
     * @notice          Function to check balance of specific token in Treasury
     * @param           token is the address of token for which the balance is requested
     */
    function getBalanceOf(
        address token
    )
    public
    view
    returns (uint)
    {
        return IERC20(token).balanceOf(address(this));
    }

}
