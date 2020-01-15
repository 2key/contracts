pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/storage-contracts/ITwoKeyFeeManagerStorage.sol";
import "../libraries/SafeMath.sol";

/**
 * @author Nikola Madjarevic (@madjarevicn)
 */
contract TwoKeyFeeManager is Upgradeable, ITwoKeySingletonUtils {
    /**
     * This contract will store the fees and users registration debts
     * Depending of user role, on some actions 2key.network will need to deduct
     * users contribution amount / earnings / proceeds, in order to cover transactions
     * paid by 2key.network for users registration
     */
    using SafeMath for *;

    bool initialized;
    ITwoKeyFeeManagerStorage PROXY_STORAGE_CONTRACT;

    //Debt will be stored in ETH
    string constant _userPlasmaToDebtInETH = "userPlasmaToDebtInETH";
    string constant _totalDebtsInETH = "totalDebtsInETH";

    string constant _totalPaidInETH = "totalPaidInETH";
    string constant _totalPaidInDAI = "totalPaidInDAI";
    string constant _totalPaidIn2Key = "totalPaidIn2Key";

    /**
     * Modifier which will allow only completely verified and validated contracts to call some functions
     */
    modifier onlyAllowedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry("TwoKeyCampaignValidator");
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }

    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyFeeManagerStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice Function where maintainer can set debts per user
     * @param usersPlasmas is the array of user plasma addresses
     * @param fees is the array containing fees which 2key paid for user
     * Only maintainer is eligible to call this function.
     */
    function setRegistrationFeesForUsers(
        address [] usersPlasmas,
        uint [] fees
    )
    public
    onlyMaintainer
    {
        uint i = 0;
        uint total = 0;
        // Iterate through all addresses and store the registration fees paid for them
        for(i = 0; i < usersPlasmas.length; i++) {
            PROXY_STORAGE_CONTRACT.setUint(keccak256(usersPlasmas[i], _userPlasmaToDebtInETH), fees[i]);
            total = total.add(fees[i]);
        }

        // Increase total debts
        bytes32 key = keccak256(_totalDebtsInETH);
        uint totalDebts = total.add(PROXY_STORAGE_CONTRACT.getUint(key));
        PROXY_STORAGE_CONTRACT.setUint(key, totalDebts);
    }



    /**
     * @notice Getter where we can check how much ETH user owes to 2key.network for his registration
     * @param _userPlasma is user plasma address
     */
    function getDebtForUser(
        address _userPlasma
    )
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_userPlasma, _userPlasmaToDebtInETH));
    }


    /**
     * @notice Internal function to cover paying debt in eth and take care of accounting for that payments
     * @param _userPlasma is the plasma address of user who is paying debt
     * @param _debt is the amount user owed to the contract
     */
    function payDebtInEth(
        address _userPlasma,
        uint _debt
    )
    internal
    {
        //Set that user's debt is now 0
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_userPlasma, _userPlasmaToDebtInETH), 0);


        // Increase amount of total debts paid to 2Key network in ETH
        bytes32 key = keccak256(_totalPaidInETH);
        uint totalPaidInEth = PROXY_STORAGE_CONTRACT.getUint(key);
        PROXY_STORAGE_CONTRACT.setUint(key, totalPaidInEth.add(_debt));
    }


    /**
     * @notice Function to check if user has some debts and if yes, take them from _amount
     * @param _plasmaAddress is the plasma address of the user
     * @param _amount is the amount of ETH involved in the action (either conversion or contractor withdraw proceeds)
     * @return leftover which user can convert with or in case of contractor -> withdraw
     */
    function payDebtWhenConvertingOrWithdrawingProceeds(
        address _plasmaAddress,
        uint _amount
    )
    public
    onlyAllowedContracts
    returns (uint)
    {
        uint debt = getDebtForUser(_plasmaAddress);
        require(_amount > debt);

        if(debt == 0) {
            return _amount;
        } else {
            payDebtInEth(_plasmaAddress, debt);
            return _amount.sub(debt);
        }
    }

    /**
     * @notice Function to get status of the debts
     */
    function getDebtsSummary()
    public
    view
    returns (uint,uint,uint,uint)
    {
        uint totalDebts = PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalDebtsInETH));
        uint totalPaidInEth = PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalPaidInETH));
        uint totalPaidInDAI = PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalPaidInDAI));
        uint totalPaidIn2Key = PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalPaidIn2Key));

        return (
            totalDebts,
            totalPaidInEth,
            totalPaidInDAI,
            totalPaidIn2Key
        );
    }

}
