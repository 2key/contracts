pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/IERC20.sol";
import "../libraries/Call.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/storage-contracts/ITwoKeyTreasuryL1Storage.sol";
import "../interfaces/IUniswapV2Router02.sol";

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


    /**
     * @notice          Function to deposit token which is not whitelisted as supported
     *                  out of the box in the application
     * @param           tokenAddress is the address of the token being deposited
     * @param           amountOfTokens is the amount of tokens user wants to deposit
     */
    function depositToken(
        address tokenAddress,
        uint amountOfTokens
    )
    public
    {
        IUniswapV2Router02 router = IUniswapV2Router02(
            getNonUpgradableContractAddressFromTwoKeySingletonRegistry(("UniswapV2Router02"))
        );

        address [] memory path = new address [](2);
        path[0] = tokenAddress;
        path[1] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");

        uint [] memory amountsOut = new uint[](2);

        amountsOut = router.getAmountsOut(
            amountOfTokens,
            path
        );

        router.swapExactTokensForTokens(
            amountOfTokens,
            amountsOut[1].mul(97).div(100), // Allow 3 percent to drop
            path,
            address(this),
            block.timestamp + (10 minutes)
        );
    }

    /**
     * @notice          Function to withdraw tokens
     * @param           beneficiary is the address receiving the tokens
     * @param           amount is the amount of tokens to withdraw
     * @param           signature is proof that msg.sender has amount of tokens he wants to withdraw
     */
    function withdrawTokens(
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
        address messageSigner = recoverSignature(msg.sender, amount, signature);

        // Assert that this signature is created by signatory address
//        require(getSignatoryAddress() == messageSigner);


    }

    /**
     * @notice          Fallback function to handle deposits in ether
     */
    function()
    public
    payable
    {

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
