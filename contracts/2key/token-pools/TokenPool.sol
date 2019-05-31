pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/IERC20.sol";
import "../upgradability/Upgradeable.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TokenPool is Upgradeable {

    bool initialized = false;
    address public erc20Address;
    address public twoKeySingletonesRegistry;
    address twoKeyMaintainersRegistry;
    address twoKeyAdmin;

    function setInitialParameters(
        address _erc20Address,
        address _twoKeySingletonesRegistry
    )
    internal
    {
        erc20Address = _erc20Address;
        twoKeySingletonesRegistry = _twoKeySingletonesRegistry;

        twoKeyMaintainersRegistry = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonesRegistry).
            getContractProxyAddress("TwoKeyMaintainersRegistry");

        twoKeyAdmin = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonesRegistry).
            getContractProxyAddress("TwoKeyAdmin");
    }

    modifier onlyMaintainer {
        require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).onlyMaintainer(msg.sender));
        _;
    }

    modifier onlyTwoKeyAdmin {
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
        return IERC20(erc20Address).balanceOf(address(this));
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
        IERC20(erc20Address).transfer(receiver,amount);
    }

}
