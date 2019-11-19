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
        address _erc20Address,
        address _proxyStorage,
        uint _twoKeyReleaseDate
    )
    public
    {
        require(initialized == false);

        PROXY_STORAGE_CONTRACT = ITwoKeyNetworkGrowthFundStorage(_proxyStorage);

        setInitialParameters(_erc20Address, _twoKeySingletonesRegistry);

        //Total amount is 96M wei
        uint portionAmount = 19200000*(10**18);
        for(uint i=1; i<=5; i++) {
            // Getting 2,3,4,5,6 years after release date
            uint releaseDate = _twoKeyReleaseDate.add((i+1).mul(1 years));
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_portionWithdrawUnlockDate, i), releaseDate);
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_portionAmountToWithdraw,i), portionAmount);
        }

        initialized = true;
    }

    function transferPortion(
        address _receiver,
        uint _amount,
        uint _portion
    )
    public
    onlyTwoKeyAdmin
    {
        //TODO: impl
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
        uint portionAmount = PROXY_STORAGE_CONTRACT.getUint(keccak256(_portionAmountToWithdraw, _portion));
        return portionAmount == 0 ? true : false;
    }



    /**
     * @notice Long term pool will hold the tokens for 3 years after that they can be transfered by TwoKeyAdmin
     * @param _receiver is the receiver of the tokens
     * @param _amount is the amount of the tokens
     */
    function transferTokensFromContract(
        address _receiver,
        uint _amount
    )
    public
    onlyTwoKeyAdmin
    {
        super.transferTokens(_receiver, _amount);
    }
}
