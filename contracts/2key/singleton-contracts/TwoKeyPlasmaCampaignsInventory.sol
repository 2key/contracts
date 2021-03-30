pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaCampaignsInventoryStorage.sol";
import "../interfaces/ITwoKeyPlasmaAccountManager.sol";
import "../interfaces/ITwoKeyPlasmaExchangeRate.sol";
import "../interfaces/ITwoKeyCPCCampaignPlasma.sol";
import "../libraries/SafeMath.sol";

 /**
  * @title TwoKeyPlasmaCampaignsInventory contract
  * @author Marko Lazic
  * Github: markolazic01
  */
contract TwoKeyPlasmaCampaignsInventory is Upgradeable {

    using SafeMath for uint;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaCampaignsInventoryStorage PROXY_STORAGE_CONTRACT;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _twoKeyPlasmaAccountManager = "TwoKeyPlasmaAccountManager";
    string constant _twoKeyPlasmaExchangeRate = "TwoKeyPlasmaExchangeRate";
    string constant _twoKeyCPCCampaignPlasma = "TwoKeyCPCCampaignPlasma";

    string constant _campaignPlasma2initialBudget2Key = "campaignPlasma2initialBudget2Key";
    string constant _campaignPlasma2isBudgetedWith2KeyDirectly = "campaignPlasma2isBudgetedWith2KeyDirectly";
    string constant _campaignPlasma2rebalancingRatio = "campaignPlasma2rebalancingRatio";
    string constant _campaignPlasma2initialRate = "campaignPlasma2initalRate";
    string constant _campaignPlasma2bountyPerConversion2KEY = "campaignPlasma2bountyPerConversion2KEY";
    string constant _campaignPlasma2amountOfStableCoins = "campaignPlasma2amountOfStableCoins";
    string constant _campaignPlasma2Contractor = "campaignPlasma2Contractor";   // msg.sender

    string constant _2KEYBalance = "2KEYBalance";
    string constant _USDBalance = "USDBalance";

    /**
     * @notice Function for contract initialization
     */
    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaCampaignsInventoryStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice      Modifier which will be used to restrict set function calls to only maintainers
     */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }

    /**
     * @notice      Function to get address from TwoKeyPlasmaSingletonRegistry
     *
     * @param       contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY).getContractProxyAddress(contractName);
    }

    /**
     * @notice          Function that allocates specified amount of 2KEY from users balance to this contract's balance
     * @notice          Function can be called only once
     */
    function addInventory2KEY(
        uint amount,
        uint bountyPerConversionUSD,
        address campaignAddressPlasma
    )
    public
    {
        // Check if user has already called this function before, if so he can not call it second time
        require(
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor)) == address(0)
        );
        // Get pair rate from ITwoKeyPlasmaExchangeRate contract
        uint rate = ITwoKeyPlasmaExchangeRate(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaExchangeRate))
        .getPairValue("2KEY-USD");
        // Calculate the bountyPerConversion2KEY value
        uint bountyPerConversion2KEY = bountyPerConversionUSD.mul(10**18).div(rate);

        // Set contractor user
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor), msg.sender);
        // Set initial 2Key budget
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialBudget2Key), amount);
        // Set current value pair rate for 2KEY-USD
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialRate), rate);
        // Set 2Key bounty per conversion value
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2bountyPerConversion2KEY), bountyPerConversion2KEY);
        // Set starting rebalancing ratio
        //TODO: 1 = 10**18, since it's decimal number afterwards --> change 1 -> 10**18
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2rebalancingRatio), 1);
        // Set true value for 2Key directly budgeting
        PROXY_STORAGE_CONTRACT.setBool(keccak256(campaignAddressPlasma, _campaignPlasma2isBudgetedWith2KeyDirectly), true);

        // Perform direct 2Key transfer
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
            .transfer2KEYFrom(msg.sender, amount);

        // Initialize CPC campaign plasma interface
        ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
        .setInitialParamsAndValidateCampaign(amount, rate, bountyPerConversion2KEY, true);
    }

    /**
     * @notice          Function that allocates specified amount of USDT from users balance to this contract's balance
     * @notice          Function can be called only once
     */
    function addInventoryUSDT(
        uint amount,
        uint bountyPerConversionUSD,
        address campaignAddressPlasma
    )
    public
    {
        // Check if user has already called this function before, if so he can not call it second time
        require(
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor)) == address(0)
        );
        // Get pair rate from ITwoKeyPlasmaExchangeRate contract
        uint rate = ITwoKeyPlasmaExchangeRate(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaExchangeRate))
        .getPairValue("2KEY-USD");
        // Calculate the bountyPerConversion2KEY value
        uint bountyPerConversion2KEY = bountyPerConversionUSD.mul(10**18).div(rate);

        // Set contractor user
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor), msg.sender);
        // Set amount of Stable coins
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2amountOfStableCoins), amount);
        // Set current rate for 2KEY-USD value pair
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialRate), rate);
        // Set current bountyPerConversion2KEY
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2bountyPerConversion2KEY), bountyPerConversion2KEY);
        // Set starting rebalancing ratio
        //TODO: 1 = 10**18, since it's decimal number afterwards --> change 1 -> 10**18
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2rebalancingRatio), 1);

        // Perform a transfer
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
        .transferUSDTFrom(msg.sender, amount);

        // Set initial parameters and validates campaign
        ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
        .setInitialParamsAndValidateCampaign(amount, rate, bountyPerConversion2KEY, false);
    }

    /**
     * @notice      Function that returns all information about given campaign
     * @param       campaignAddressPlasma is address of the campaign
     */
    function getCampaignInventory(
    //TODO: Rename to getCamapignInformation
        address campaignAddressPlasma
    )
    public
    view
    returns(
        address,
        uint,
        uint,
        uint,
        uint,
        uint,
        bool
    )
    {
        return(
            // Gets campaigns contractor
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor)),
            // Gets campaigns initial 2KEY budget
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialBudget2Key)),
            // Gets campaigns amount of Stable coins
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2amountOfStableCoins)),
            // Gets the initial rate
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialRate)),
            // Gets bounty per conversion in 2KEY
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2bountyPerConversion2KEY)),
            // Gets rebalancing ratio (default value is 1)
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2rebalancingRatio)),
            // Gets boolean value if campaign is budgeted directly with 2Key currency
            PROXY_STORAGE_CONTRACT.getBool(keccak256(campaignAddressPlasma, _campaignPlasma2isBudgetedWith2KeyDirectly))
        );
    }

    function endCampaignReserveTokensAndRebalanceRates(
        address campaignPlasma,
        uint totalAmountForReferrerRewards,
        uint totalAmountForModeratorRewards
    )
    public
    {

    }

}
