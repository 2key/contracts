pragma solidity ^0.4.24;

import "./TokenPool.sol";
import "../interfaces/storage-contracts/ITwoKeyNetworkGrowthFundStorage.sol";
import "../libraries/SafeMath.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TwoKeyNetworkGrowthFund is TokenPool {

    string constant _releaseDate = "releaseDate";
    string constant _portionWithdrawUnlockDate = "portionWithdrawUnlockDate";
    string constant _portionAmountToWithdraw = "portionAmountToWithdraw";

    using SafeMath for *;

    ITwoKeyNetworkGrowthFundStorage public PROXY_STORAGE_CONTRACT;


    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage,
        uint _twoKeyReleaseDate
    )
    public
    {
        require(initialized == false);

        PROXY_STORAGE_CONTRACT = ITwoKeyNetworkGrowthFundStorage(_proxyStorage);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;

        //Total amount is 96M wei
        uint portionAmount = getContractBalance();

        for(uint i=1; i<=5; i++) {
            // Getting 2,3,4,5,6 years after release date
            uint releaseDate = _twoKeyReleaseDate.add((i+1).mul(1 years));
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_portionWithdrawUnlockDate, i), releaseDate);
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_portionAmountToWithdraw,i), portionAmount); //TODO: Nikola - make sure this is supposed to be balance/number of portions - per year
        }

        initialized = true;
    }

    function overrideStoredPortionsWithRightValues()
    public
    {
        //TODO: Update contract, patch, and delete this function + patch again
        uint portionsTotal = getContractBalance();
        uint portionAmount = portionsTotal.div(5);

        for(uint i=1; i<=5; i++) {
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_portionAmountToWithdraw,i), portionAmount);
        }
    }

    function transferPortion(
        address _receiver,
        uint _amount,
        uint _portion
    )
    public
    onlyTwoKeyAdmin
    {
        require(getPortionUnlockingDate(_portion) <= block.timestamp);
        require(getAmountLeftForThePortion(_portion) <= _amount);

        super.transferTokens(_receiver, _amount);

        PROXY_STORAGE_CONTRACT.setUint(keccak256(_portionAmountToWithdraw, _portion), getAmountLeftForThePortion(_portion)- _amount);

    }

    function getPortionUnlockingDate(
        uint _portion
    )
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_portionWithdrawUnlockDate,_portion));
    }


    function isPortionWithdrawn(
        uint _portion
    )
    public
    view
    returns (bool)
    {
        uint portionAmount = getAmountLeftForThePortion(_portion);
        return portionAmount == 0 ? true : false;
    }

    function getAmountLeftForThePortion(
        uint _portion
    )
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_portionAmountToWithdraw, _portion));
    }

}
