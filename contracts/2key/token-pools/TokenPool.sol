pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/IERC20.sol";
import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TokenPool is Upgradeable, ITwoKeySingletonUtils {

    bool initialized = false;

    modifier onlyTwoKeyAdmin {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        require(msg.sender == twoKeyAdmin);
        _;
    }

    /**
     * @notice Function to retrieve the balance of tokens on the contract
     */
    function getContractBalance()
    public
    view
    returns (uint)
    {
        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        return IERC20(twoKeyEconomy).balanceOf(address(this));
    }

    /**
     * @notice Function to transfer tokens
     */
    function transferTokens(
        address receiver,
        uint amount
    )
    internal
    {
        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        IERC20(twoKeyEconomy).transfer(receiver,amount);
    }

}
