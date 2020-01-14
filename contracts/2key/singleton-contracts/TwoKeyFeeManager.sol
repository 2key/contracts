pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyFeeManagerStorage.sol";

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

    bool initialized;
    ITwoKeyFeeManagerStorage PROXY_STORAGE_CONTRACT;

    string constant _userPlasmaToDebt = "userPlasmaToDebt";
    string constant _totalDebts = "totalDebts";
    string constant _totalPaid = "totalPaid";

    /**
     * Modifier which will allow only completely verified and validated contracts to call some functions
     */
    modifier onlyAllowedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
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
            PROXY_STORAGE_CONTRACT.setUint(keccak256(usersPlasmas[i], _userPlasmaToDebt), fees[i]);
            total = total + fees[i];
        }

        // Increase total debts
        bytes32 key = keccak256(_totalDebts);
        uint totalDebts = PROXY_STORAGE_CONTRACT.getUint(key) + total;
        PROXY_STORAGE_CONTRACT.setUint(key, totalDebts);
    }



    /**
     * @notice Getter where we can check how much user owes to 2key.network
     * @param _userPlasma is user plasma address
     */
    function getDebtForUser(
        address _userPlasma
    )
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_userPlasma, _userPlasmaToDebt));
    }


    /**
     * @notice Function to get current debt users are owing to 2key.network
     */
    function getDebtTo2key()
    public
    view
    returns (uint,uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalDebts)) - PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalPaid));
    }

//    function checkIfUserHaveAnyDebt(
//        address plasma
//    )



    function payDebt(
        address ethereumAddress
    )
    public
    onlyValidatedContracts
    {

    }



}
