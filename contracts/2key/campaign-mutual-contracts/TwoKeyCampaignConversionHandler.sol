pragma solidity ^0.4.24;

import "../TwoKeyConverterStates.sol";
import "../TwoKeyConversionStates.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";

contract TwoKeyCampaignConversionHandler is TwoKeyConversionStates, TwoKeyConverterStates {

    using SafeMath for uint256;
    bool isCampaignInitialized;
    uint numberOfConversions;


    /**
     * This array will represent counter values where position will be index (which counter) and value will be actual counter value
     * counters[0] = PENDING_CONVERSIONS
     * counters[1] = APPROVED_CONVERSIONS
     * counters[2] = REJECTED_CONVERSIONS
     * counters[3] = EXECUTED_CONVERSIONS
     * counters[4] = CANCELLED_CONVERSIONS
     * counters[5] = UNIQUE_CONVERTERS
     * counters[6] = RAISED_FUNDS_ETH_WEI
     * counters[7] = TOKENS_SOLD
     * counters[8] = TOTAL_BOUNTY
     * counters[9] = RAISED_FUNDS_FIAT_WEI
     */
    uint [] counters;

    address contractor;
    address twoKeyEventSource;
    address twoKeyBaseReputationRegistry;
    address twoKeySingletonRegistry;
    address public twoKeyPurchasesHandler;


    mapping(address => uint256) internal amountConverterSpentEthWEI; // Amount converter put to the contract in Ether

    mapping(bytes32 => address[]) stateToConverter; //State to all converters in that state
    mapping(address => uint[]) converterToHisConversions;
    mapping(address => ConverterState) converterToState; //Converter to his state
    mapping(address => bool) isConverterAnonymous;
    mapping(address => bool) doesConverterHaveExecutedConversions;


    modifier onlyContractorOrMaintainer {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        require(msg.sender == contractor || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).onlyMaintainer(msg.sender));
        _;
    }


    // Internal function to fetch address from TwoKeySingletonRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry)
        .getContractProxyAddress(contractName);
    }

    /**
     * given the total payout, calculates the moderator fee
     * @param  _conversionAmountETHWei total payout for escrow
     * @return moderator fee
     */
    function calculateModeratorFee(
        uint256 _conversionAmountETHWei
    )
    internal
    view
    returns (uint256)
    {
        uint256 fee = _conversionAmountETHWei.mul(ITwoKeyEventSource(twoKeyEventSource).getTwoKeyDefaultIntegratorFeeFromAdmin()).div(100);
        return fee;
    }


}
