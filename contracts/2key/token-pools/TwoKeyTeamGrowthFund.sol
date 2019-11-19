pragma solidity ^0.4.24;

import "./TokenPool.sol";
import "../interfaces/storage-contracts/ITwoKeyTeamGrowthFundStorage.sol";

contract TwoKeyTeamGrowthFund is TokenPool {

    string constant _tokensReleaseDate = "tokensReleaseDate";

    ITwoKeyTeamGrowthFundStorage public PROXY_STORAGE_CONTRACT;

    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorageContract
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyTeamGrowthFundStorage(_proxyStorageContract);

        PROXY_STORAGE_CONTRACT.setUint(keccak256(_tokensReleaseDate), block.timestamp + (2 years));
        initialized = true;
    }

    /**
     * Modifier which will restrict transferring tokens if release date
     * has not passed yet
     */
    modifier onlyAfterReleaseDatePassed {
        require(block.timestamp >= getTokensReleaseDate());
        _;
    }

    /**
     * @notice Function to get release date when this tokens can be transferred
     * @return timestamp
     */
    function getTokensReleaseDate()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_tokensReleaseDate));
    }

    /**
     * @notice Function to transfer tokens from contract
     * @param _beneficiary is the address where tokens are being transferred
     * @param _amount is the WEI amount of tokens
     */
    function transferTokensFromContract(
        address _beneficiary,
        uint _amount
    )
    public
    onlyAfterReleaseDatePassed
    onlyTwoKeyAdmin
    {
        super.transferTokens(_beneficiary, _amount);
    }




}
