pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

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
import "../interfaces/ITwoKeyAdmin.sol";

import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";

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
    string constant _twoKeyCongress = "TwoKeyCongress";

    bool initialized;

    ITwoKeyTreasuryL1Storage public PROXY_STORAGE_CONTRACT;

    mapping(address => mapping(address => uint)) public userTokenDepositAmount;  // user => token => amount
    mapping(address => uint) public userETHDepositAmount;    // user => amount
    mapping(address => uint) public userUSDDepositBalance; // user => amount
    mapping(address => uint) public userUSDWithdrawBalance;   // user => amount
    mapping(address => uint) public user2KEYWithdrawBalance;   // user => amount
    mapping(bytes32 => bool) public isSignatureRateValid; // signature => bool
    address public targetPegToken;  // target peg token address

    event Deposit2KEY(address indexed depositor, uint amount);
    event DepositStableCoin(address indexed depositor, uint amount);
    event DepositVolatileToken(address indexed depositor, address indexed fromTokenAddress, uint fromAmount, address toTokenAddress, uint toTokenAmount, uint buyRate);
    event DepositETH(address indexed depositor, uint amount, address toTokenAddress, uint toTokenAmount, uint daiBuyRate);
    event WithdrawToken(address indexed beneficiary, address indexed token, uint amount);
    event ReportSignatureValidation(bytes signature, bool indexed isValidSignature);

    /**
	 * @notice 			Modifier which throws if caller is not TwoKeyCongress
	 */
	modifier onlyTwoKeyCongress {
		require(msg.sender == getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyCongress));
	    _;
	}

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
     * @param           amountOfTokens is the amount of pending rewards user wants to claim
     * @param           signature is the signature created by maintainer
     */
    function recoverSignatureForModeratorUSD(
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
                keccak256(abi.encodePacked(amountOfTokens))
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
    function recoverSignatureForModerator2KEY(
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
                keccak256(abi.encodePacked(amountOfTokens))
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
            require(IERC20(token).transferFrom(msg.sender, address(this), amount));

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
    
            emit DepositVolatileToken(msg.sender, token, amount, getTokenAddress("DAI"), daiAmount, daiBuyRate);
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

        emit DepositETH(userAddress, amount, getTokenAddress("DAI"), daiAmount, daiBuyRate);
    }

    /**
     * @notice set target peg token
     */
    function setTargetPegToken(address tokenAddress)
    public
    onlyTwoKeyCongress
    {
        targetPegToken = tokenAddress;
    }

    /**
     * @notice          Function to withdraw moderator USD balance
     * @param           amount is USD amount
     * @param           signature is proof that beneficiary has amount of tokens he wants to withdraw
     */
    function withdrawModeratorBalanceUSD(
        uint amount,
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
        address messageSigner = recoverSignatureForModeratorUSD(amount, signature);
        // Get the instance of TwoKeyRegistry
        ITwoKeyRegistry registry = ITwoKeyRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));
        // Assert that this signature is created by signatory address
        require(messageSigner == registry.getSignatoryAddress());

        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        
        ITwoKeyAdmin(twoKeyAdmin).addUSDWithdrawnAsModerator(amount);

        require(IERC20(targetPegToken).transfer(twoKeyAdmin, amount));

        emit WithdrawToken(twoKeyAdmin, targetPegToken, amount);
    }

    /**
     * @notice          Function to withdraw moderator 2KEY balance
     * @param           amount is the amount of tokens to withdraw
     * @param           signature is proof that beneficiary has amount of tokens he wants to withdraw
     */
    function withdrawModeratorBalance2KEY(
        uint amount,
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
        address messageSigner = recoverSignatureForModerator2KEY(amount, signature);
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
    function withdrawL2BalanceUSD(
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
        address messageSigner = recoverSignatureForReferrerUSD(beneficiary, amount, buy2keyRateL2, signature);
        // Get the instance of TwoKeyRegistry
        ITwoKeyRegistry registry = ITwoKeyRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));
        // Assert that this signature is created by signatory address
        require(messageSigner == registry.getSignatoryAddress());
        // Require that beneficiary is msg.sender
        require(beneficiary == msg.sender);

        address twoKeyTokenAddress = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");

        // Get the current 2key buy rate
        uint uniswap2keyRate = getUniswap2KeyBuyPriceInUSD(targetPegToken);

        // Allow 5% change of the price
        if (uniswap2keyRate >= buy2keyRateL2.mul(95).div(100) && uniswap2keyRate <= buy2keyRateL2.mul(105).div(100)) {
            isSignatureRateValid[keccak256(signature)] = true;

            uint withdrawBalance2KEY = amount.div(buy2keyRateL2).mul(10**18);
            // safeguard
            require(amount <= getTotalUSDBalanceOfNon2KEYTokens());

            userUSDWithdrawBalance[beneficiary] = userUSDWithdrawBalance[beneficiary].add(amount);
            // Transfer tokens to the user
            IERC20(twoKeyTokenAddress).transfer(beneficiary, withdrawBalance2KEY);

            emit WithdrawToken(beneficiary, twoKeyTokenAddress, withdrawBalance2KEY);
            emit ReportSignatureValidation(signature, true);
        } else {
            emit ReportSignatureValidation(signature, false);
        }
    }

    /**
     * @notice          Function to withdraw ERC20 token
     * @param           beneficiary is the user to withdraw token
     * @param           amount is the amount of tokens to withdraw
     * @param           signature is proof that maintainer is the message signer
     */
    function withdrawL2Balance2KEY(
        address beneficiary,
        uint amount,
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
        address messageSigner = recoverSignatureForReferrer2KEY(beneficiary, amount, signature);
        // Get the instance of TwoKeyRegistry
        ITwoKeyRegistry registry = ITwoKeyRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));
        // Assert that this signature is created by signatory address
        require(messageSigner == registry.getSignatoryAddress());
        // Require that beneficiary is msg.sender
        require(beneficiary == msg.sender);

        address twoKeyTokenAddress = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");

        uint withdrawBalance2KEY = amount;
        // safeguard
        uint usdValue = getUniswap2KeyBuyPriceInUSD(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).mul(withdrawBalance2KEY).div(10**18);
        require(usdValue <=  getTotalUSDBalanceOfNon2KEYTokens());

        user2KEYWithdrawBalance[beneficiary] = user2KEYWithdrawBalance[beneficiary].add(withdrawBalance2KEY);

        // Transfer tokens to the user
        IERC20(twoKeyTokenAddress).transfer(beneficiary, withdrawBalance2KEY);

        emit WithdrawToken(beneficiary, twoKeyTokenAddress, withdrawBalance2KEY);
    }

    function getUniswap2KeyBuyPriceInUSD(
        address tokenAddress
    )
    internal
    returns (uint256) {
        address [] memory path = new address[](3);

        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        path[0] = tokenAddress;
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

    /**
     * @notice          Function to get USD value of non-2key tokens on contract
     * @return          Returns USD value
     */
    function getTotalUSDBalanceOfNon2KEYTokens()
    internal
    view
    returns (uint)
    {
        uint usdBalance;
        address tokenAddress;

        // BUSD
        tokenAddress = getTokenAddress("BUSD");
        usdBalance = usdBalance.add(getBalanceOf(tokenAddress).mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));
        // TUSD
        tokenAddress = getTokenAddress("TUSD");
        usdBalance = usdBalance.add(getBalanceOf(tokenAddress).mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));
        // PAX
        tokenAddress = getTokenAddress("PAX");
        usdBalance = usdBalance.add(getBalanceOf(tokenAddress).mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));
        // DAI
        tokenAddress = getTokenAddress("DAI");
        usdBalance = usdBalance.add(getBalanceOf(tokenAddress).mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));
        // USDC
        tokenAddress = getTokenAddress("USDC");
        usdBalance = usdBalance.add(getBalanceOf(tokenAddress).mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));
        // USDT
        tokenAddress = getTokenAddress("USDT");
        usdBalance = usdBalance.add(getBalanceOf(tokenAddress).mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));
        // RENBTC
        tokenAddress = getTokenAddress("RENBTC");
        usdBalance = usdBalance.add(getBalanceOf(tokenAddress).mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));
        // WBTC
        tokenAddress = getTokenAddress("WBTC");
        usdBalance = usdBalance.add(getBalanceOf(tokenAddress).mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));
        // WETH
        tokenAddress = getTokenAddress("WETH");
        usdBalance = usdBalance.add(getBalanceOf(tokenAddress).mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));
        // ETH
        tokenAddress = getTokenAddress("WETH");
        usdBalance = usdBalance.add(address(this).balance.mul(getUniswap2KeyBuyPriceInUSD(tokenAddress)).div(10**18));

        return usdBalance;
    }

    /**
     * @notice Swap all non-2KEY tokens for targetPegToken
     */
    function pegAllAssets()
    public
    onlyMaintainer
    {
        address[] memory tokenList = new address[](9);
        address tokenAddress;

        // BUSD
        tokenList[0] = getTokenAddress("BUSD");
        // TUSD
        tokenList[1] = getTokenAddress("TUSD");
        // PAX
        tokenList[2] = getTokenAddress("PAX");
        // DAI
        tokenList[3] = getTokenAddress("DAI");
        // USDC
        tokenList[4] = getTokenAddress("USDC");
        // USDT
        tokenList[5] = getTokenAddress("USDT");
        // RENBTC
        tokenList[6] = getTokenAddress("RENBTC");
        // WBTC
        tokenList[7] = getTokenAddress("WBTC");
        // WETH
        tokenList[8] = getTokenAddress("WETH");

        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        // create a path array
        address[] memory path = new address[](2);

        for (uint i; i < tokenList.length; i++) {
            // Load the token address
            tokenAddress = tokenList[i];

            // Require that token address is not the same as targtPegToken
            if (tokenAddress != targetPegToken) {
                uint amountToSwap = IERC20(tokenAddress).balanceOf(address(this));

                if (amountToSwap > 0 ) {
                    // Approve uniswap router to take tokens form the contract
                    IERC20(tokenAddress).approve(
                        uniswapRouter,
                        amountToSwap
                    );

                    // Set path array
                    path[0] = tokenAddress;
                    path[1] = targetPegToken;

                    // Get minimum received
                    uint minimumToReceive = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).uniswapPriceDiscoverForBuyingFromUniswap(
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
        }

        // swap ETH
        path[0] = IUniswapV2Router02(uniswapRouter).WETH();
        path[1] = targetPegToken;
        amountToSwap = address(this).balance;

        // Get minimum received
        minimumToReceive = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).uniswapPriceDiscoverForBuyingFromUniswap(
            uniswapRouter,
            amountToSwap,
            path
        );

        // Execute swap
        IUniswapV2Router01(uniswapRouter).swapExactETHForTokens(
            minimumToReceive.mul(97).div(100), // Allow 3 percent to drop
            path,
            address(this),
            block.timestamp + (10 minutes)
        );
    }

    /**
     * @notice Swap all non-2KEY tokens for targetPegToken
     */
    function pegAssets(
        string[] symbolList
    )
    public
    onlyMaintainer
    {
        address[] memory tokenList;
        address tokenAddress;

        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        // create a path array
        address[] memory path = new address[](2);

        for (uint i; i < symbolList.length; i++) {
            // Load the token address
            tokenAddress = getTokenAddress(symbolList[i]);

            // Require that token address is not the same as targtPegToken
            if (tokenAddress != targetPegToken) {
                uint amountToSwap = IERC20(tokenAddress).balanceOf(address(this));

                if (amountToSwap > 0) {
                    // Approve uniswap router to take tokens form the contract
                    IERC20(tokenAddress).approve(
                        uniswapRouter,
                        amountToSwap
                    );

                    // Set path array
                    path[0] = tokenAddress;
                    path[1] = targetPegToken;

                    // Get minimum received
                    uint minimumToReceive = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).uniswapPriceDiscoverForBuyingFromUniswap(
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
        }
    }
}
