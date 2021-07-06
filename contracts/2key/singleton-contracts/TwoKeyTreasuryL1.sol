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


    bool initialized;

    ITwoKeyTreasuryL1Storage public PROXY_STORAGE_CONTRACT;

    mapping(address => mapping(address => uint)) public depositStatsToken;  // user => token => amount
    mapping(address => uint) public depositStatsETH;    // user => amount
    mapping(address => uint) public depositUserTotalBalanceUSD; // user => amount
    mapping(address => uint) public withdrawnUserTotalBalanceUSD;   // user => amount

    uint stableTokenBalanceUSD;
    uint nonStableTokenBalanceUSD;
    uint totalDepositedUSD; // stableTokenBalanceUSD + nonStableTokenBalanceUSD
    uint totalDeposited2KEY;

    uint totalWithdrawnUSD;
    uint totalWithdrawn2KEY;

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
     * @notice          Function to return who signed msg
     * @param           userAddress is the address of user for who we signed message
     * @param           amountOfTokens is the amount of pending rewards user wants to claim
     * @param           buy2keyRateL2 is the 2key rate sent by maintainer
     * @param           signature is the signature created by maintainer
     */
    function recoverSignature(
        address userAddress,
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
                keccak256(abi.encodePacked(userAddress, amountOfTokens, buy2keyRateL2))
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

        depositStatsToken[msg.sender][token] = depositStatsToken[msg.sender][token].add(amount);
        totalDeposited2KEY = totalDeposited2KEY.add(amount);

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

        if (token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("BUSD") ||
            token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TUSD") ||
            token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("PAX") ||
            token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI") ||
            token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("USDC")
        ) {
            require(amount <= IERC20(token).allowance(msg.sender, address(this)));
            require(IERC20(token).transferFrom(msg.sender, address(this), amount));

            depositStatsToken[msg.sender][token] = depositStatsToken[msg.sender][token].add(amount);
            depositUserTotalBalanceUSD[msg.sender] = depositUserTotalBalanceUSD[msg.sender].add(amount);
            stableTokenBalanceUSD = stableTokenBalanceUSD.add(amount);
            totalDepositedUSD = totalDepositedUSD.add(amount);
    
            emit DepositStableCoin(msg.sender, amount);

        } else if(token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("USDT")) {
            require(amount <= ITether(token).allowance(msg.sender, address(this)));
            ITether(token).transferFrom(msg.sender, address(this), amount);

            depositStatsToken[msg.sender][token] = depositStatsToken[msg.sender][token].add(amount);
            depositUserTotalBalanceUSD[msg.sender] = depositUserTotalBalanceUSD[msg.sender].add(amount);
            stableTokenBalanceUSD = stableTokenBalanceUSD.add(amount);
            totalDepositedUSD = totalDepositedUSD.add(amount);

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

        if (token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("RENBTC") ||
            token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("WBTC") ||
            token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("WETH")
        ) {
            require(amount <= IERC20(token).allowance(msg.sender, address(this)));
            require(IERC20(token).transferFrom(msg.sender, address(this), amount));

            (uint daiAmount, uint daiBuyRate) = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).simulateBuyStableCoinWithERC20(amount, token);

            depositStatsToken[msg.sender][token] = depositStatsToken[msg.sender][token].add(daiAmount);
            depositUserTotalBalanceUSD[msg.sender] = depositUserTotalBalanceUSD[msg.sender].add(daiAmount);
            nonStableTokenBalanceUSD = nonStableTokenBalanceUSD.add(daiAmount);
            totalDepositedUSD = totalDepositedUSD.add(daiAmount);
    
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

        depositStatsETH[msg.sender] = depositStatsETH[msg.sender].add(daiAmount);
        depositUserTotalBalanceUSD[msg.sender] = depositUserTotalBalanceUSD[msg.sender].add(daiAmount);
        nonStableTokenBalanceUSD = nonStableTokenBalanceUSD.add(daiAmount);
        totalDepositedUSD = totalDepositedUSD.add(daiAmount);

        emit DepositETH(userAddress, amount, getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI"), daiAmount, daiBuyRate);
    }

    /**
     * @notice          Function to withdraw ERC20 token
     * @param           beneficiary is the address receiving the tokens
     * @param           amount is the amount of tokens to withdraw
     * @param           buy2keyRateL2 is the 2key price set by maintainer
     * @param           signature is proof that msg.sender has amount of tokens he wants to withdraw
     */
    function withdrawTokens(
        address beneficiary,
        uint amount,
        uint buy2keyRateL2,
        bytes signature
    )
    public
    {
        bytes32 key = keccak256(_isExistingSignature, signature);
        // Require that signature doesn't exist
        require(PROXY_STORAGE_CONTRACT.getBool(key) == false);
        // Set that this signature is used and exists
        PROXY_STORAGE_CONTRACT.setBool(key, true);
        // Check who signed the message
        address messageSigner = recoverSignature(msg.sender, amount, buy2keyRateL2, signature);
        // Get the instance of TwoKeyRegistry
        ITwoKeyRegistry registry = ITwoKeyRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));
        // Assert that this signature is created by signatory address
        require(messageSigner == registry.getSignatoryAddress());

        // Get the current 2key buy rate
        uint uniswap2keyRate = getUniswap2KeyBuyPriceInUSD();

        // Allow 10% change of the price
        require(uniswap2keyRate >= buy2keyRateL2.mul(9).div(10), "TwoKeyTreasuryL1: Invalid 2key price");
        require(uniswap2keyRate <= buy2keyRateL2.mul(11).div(10), "TwoKeyTreasuryL1: Invalid 2key price");

        // safeguard
        uint withdrawBalanceUSD = amount.div(buy2keyRateL2).mul(10**18);
        require(withdrawBalanceUSD <= depositUserTotalBalanceUSD[beneficiary].sub(withdrawnUserTotalBalanceUSD[beneficiary]), "TwoKeyTreasuryL1: Exceeds witdraw amount");

        withdrawnUserTotalBalanceUSD[beneficiary] = withdrawnUserTotalBalanceUSD[beneficiary].add(withdrawBalanceUSD);
        totalWithdrawnUSD = totalWithdrawnUSD.add(withdrawBalanceUSD);
        totalWithdrawn2KEY = totalWithdrawn2KEY.add(amount);

        // Get the instance of 2KEY token contract
        IERC20 twoKeyEconomy = IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy"));
        // Transfer tokens to the user
        twoKeyEconomy.transfer(beneficiary, amount);

        emit WithdrawToken(beneficiary, address(twoKeyEconomy), amount);
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
