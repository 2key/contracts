pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/IERC20.sol";
import "../libraries/Call.sol";

/**
 * TwoKeyTreasuryL1 contract receiving all deposits from contractors.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract TwoKeyTreasuryL1 is Upgradeable, ITwoKeySingletonUtils {

    string constant _isExistingSignature = "isExistingSignature";


    /**
     * @notice          Function to deposit token which is not whitelisted as supported
     *                  out of the box in the application
     * @param           tokenAddress is the address of the token being deposited
     * @param           amountOfTokens is the amount of tokens user wants to deposit
     */
    function depositToken(
        address tokenAddress
    )
    public
    {
        //TODO: Implement Uniswap swap funnel for 2KEY
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
