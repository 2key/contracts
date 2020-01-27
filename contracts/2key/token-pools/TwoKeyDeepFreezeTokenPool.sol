pragma solidity ^0.4.24;

import "./TokenPool.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/storage-contracts/ITwoKeyDeepFreezeTokenPoolStorage.sol";

/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TwoKeyDeepFreezeTokenPool is TokenPool {

    ITwoKeyDeepFreezeTokenPoolStorage public PROXY_STORAGE_CONTRACT;

    string constant _tokensReleaseDate = "tokensReleaseDate";
    string constant _tokensReceivedFromModeratorRewards = "tokensReceivedFromModeratorRewards";

    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
    string constant _twoKeyEventSource = "TwoKeyEventSource";

    address public twoKeyParticipationMiningPool;

    modifier onlyAllowedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }

    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _twoKeyParticipationMiningPool,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;

        PROXY_STORAGE_CONTRACT = ITwoKeyDeepFreezeTokenPoolStorage(_proxyStorage);
        twoKeyParticipationMiningPool = _twoKeyParticipationMiningPool;

        PROXY_STORAGE_CONTRACT.setUint(keccak256(_tokensReleaseDate), block.timestamp + 10 * (1 years));

        initialized = true;
    }

    /**
     * @notice Function can transfer tokens only after 10 years to community token pool
     * @param amount is the amount of tokens we're sending
     * @dev only two key admin can issue a call to this method
     */
    function transferTokensToCommunityPool(
        uint amount
    )
    public
    onlyTwoKeyAdmin
    {
        uint tokensReleaseDate = PROXY_STORAGE_CONTRACT.getUint(keccak256(_tokensReleaseDate));

        require(getContractBalance() >= amount);
        require(block.timestamp > tokensReleaseDate);
        super.transferTokens(twoKeyParticipationMiningPool,amount);
    }

    function updateReceivedTokensForSuccessfulConversions(
        uint amountOfTokens,
        address campaignAddress
    )
    public
    onlyTwoKeyAdmin
    {
        bytes32 keyHashTotalRewards = keccak256(_tokensReceivedFromModeratorRewards);
        PROXY_STORAGE_CONTRACT.setUint(keyHashTotalRewards, amountOfTokens + (PROXY_STORAGE_CONTRACT.getUint(keyHashTotalRewards)));

        //Emit event through TwoKeyEventSource for the campaign
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource)).emitReceivedTokensToDeepFreezeTokenPool(campaignAddress, amountOfTokens);
    }


}
