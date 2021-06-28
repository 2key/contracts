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

    string constant _twoKeyPlasmaAccountManager = "TwoKeyPlasmaAccountManager";


    bool initialized;

    ITwoKeyTreasuryL1Storage public PROXY_STORAGE_CONTRACT;

    event DepositEther(address indexed depositor, uint256 amount);
    event DepositToken(address indexed depositor, address indexed token, uint256 amount);
    event WithdrawToken(address indexed beneficiary, address indexed token, uint256 amount);


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
        emit DepositEther(msg.sender, msg.value);
    }

    /**
     * @notice          Function to return who signed msg
     * @param           userAddress is the address of user for who we signed message
     * @param           amountOfTokens is the amount of pending rewards user wants to claim
     * @param           signature is the signature created by maintainer
     */
    function recoverSignature(
        address userAddress,
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
                keccak256(abi.encodePacked(userAddress,amountOfTokens))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash,signature,0);
    }

    //TODO: there should be different deposit for 2KEY (because for 2KEY we don't compute USD worth) - if you deposit 2KEY, you get L2_2KEY

    function deposit2KEY(
        address token,
        uint amount
    )
    public
    {
        require(token != address(0), "TwoKeyTreasuryL1: Invalid token address");
        require(token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("2KEY"), "TwoKeyTreasuryL1: Not 2Key token");
        require(amount > 0, "TwoKeyTreasuryL1: Token amount to deposit must be greater than zero");

        
        require(amount <= IERC20(token).allowance(msg.sender, address(this)));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount));

        emit DepositToken(msg.sender, token, amount);
    }

    /**
     * @notice          Function to deposit ERC20 token
     * @param           token is the address of the token being deposited
     * @param           amount is the amount of token to deposit
     */
    function depositToken(  //TODO whatever is deposited through here (non-2KEY) geberates a transfer of L2_USD on L2
        address token,
        uint amount
    )
    public
    {
        require(token != address(0), "TwoKeyTreasuryL1: Invalid token address");
        require(amount > 0, "TwoKeyTreasuryL1: Token amount to deposit must be greater than zero");
        //TODO we allow to add only specific types of tokens - USDT/BUSD/USDC/TUSD/PAX/DAI RENBTC/WBTC/ETH
        //TODO make sure the deposited tokens are only in the above set
        if (token == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("USDT")) {
            // Take USDT from the user
            require(amount <= ITether(token).allowance(msg.sender, address(this)));
            ITether(token).transferFrom(msg.sender, address(this), amount);
        } else {
            // Take ERC20 token from the user
            require(amount <= IERC20(token).allowance(msg.sender, address(this)));
            require(IERC20(token).transferFrom(msg.sender, address(this), amount));
        }
        //TODO: add balances from erc20 address to amount of deposited tokens map<address-->uint>
        //TOOD: updated deposited tokens amount in the above mapping
        //TODO: add local var in this function depositUSDWorth and compute it (either 1:1 is stable, or via chainlink is eth/renbtc/wbtc)
        //TODO: add 1 global param stableTokenBalanceUSD = add to it when deposited token is stable (no need to convert, we assume 1:1 with usd)
        //TODO: if deposited token not stable, use chainlink to get usd amount, and update another global variable = nonStableTokenBalanceUSD
        //TODO: add 1 global param totalDepositedUSD = add to it from both of the above
        //TODO: compile signature by contract of depositUSDWorth
        emit DepositToken(msg.sender, token, amount); //TODO: BE needs to pick this up from graph to validate / or from frontend by tx_hash and make sure not to deal more than once
        //TODO: add depositUSDWorth in event

        //TODO: fe sends tx, updates be with tx_hash, backend verified status on chain + verifies event + usd worth
        //TODO: backend has signature from l1 contract attesting to deposited usd worth
        //TODO: layer2 contract PlasmaTreasuryL2.sol (plasmaAccountManager) - when first deployed, 2 ERC20 tokens are created/minted on layer2 (L2_2KEY, L2_USD), and entire balance is assigned to PlasmaTreasuryL2
        //TODO: PlasmaTreasureL2.sol:
        //          1. spendingAllowance (set by congress, initialized at 100K USD, can be updated by congress)
        //          2. initialized with the treasuryl1 proxy address (some immutable address), or the address that will be the signer of despositUSDWorth
        //          3. maintainer only can submit transfer command, which will verify the amount in USD is equal to the signature and that signature is made by the address of treasuryl1


    }

    /**
     * @notice          Function to withdraw ERC20 token
     * @param           beneficiary is the address receiving the tokens
     * @param           amount is the amount of tokens to withdraw
     * @param           signature is proof that msg.sender has amount of tokens he wants to withdraw
     */
    function withdrawTokens(
        address beneficiary,
        uint amount,
        bytes signature
    //TODO add 2key-usd rate in params (will be supplied by client from 2key backend)
    //TODO: on 2nd layer, maintainers (in-house oracles) will update 2key-rate
    )
    public
    {
        //TODO: Add security safeguards = verify that signature also signed on 2key-rate
        //TODO: checksum that 2key-rate is within 10% error buffer from curret rate from uniswap
        //TODO: add global variable totalWithdrawnUSD - counts value in $ of all withdrawn 2KEY up till now
        //TODO: add global variable totalWithdrawn2KEY - counts number of 2KEY withdrawn up till now
        //TODO: checksum that amountx2key_usd rate (i.e. the value of withdraw in $) is < totalDepositedUSD-totalWithdrawnUSD)

        //TODO: update value of totalWithdrawnUSD (+=) with computed amountx2key_usd value
        //TODO: update value of totalWithdrawn2KEY (+=) with amount

        bytes32 key = keccak256(_isExistingSignature, signature);
        // Require that signature doesn't exist
        require(PROXY_STORAGE_CONTRACT.getBool(key) == false);
        // Set that this signature is used and exists
        PROXY_STORAGE_CONTRACT.setBool(key, true);
        // Check who signed the message
        address messageSigner = recoverSignature(msg.sender, amount, signature);
        // Get the instance of TwoKeyRegistry
        ITwoKeyRegistry registry = ITwoKeyRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));
        // Assert that this signature is created by signatory address
        require(messageSigner == registry.getSignatoryAddress());
        // Get the instance of 2KEY token contract
        IERC20 twoKeyEconomy = IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy"));
        // Transfer tokens to the user
        twoKeyEconomy.transfer(beneficiary, amount);

        emit WithdrawToken(beneficiary, address(twoKeyEconomy), amount);

        //TODO: add
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
