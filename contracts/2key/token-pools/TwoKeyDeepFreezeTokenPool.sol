pragma solidity ^0.4.24;

import "./TokenPool.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TwoKeyDeepFreezeTokenPool is TokenPool {

    uint tokensReleaseDate;
    address public twoKeyCommunityTokenPool;

    function setInitialParams(address _erc20Address, address _twoKeyAdmin, address _twoKeyCommunityTokenPool) public {
        require(initialized == false);
        erc20Address = _erc20Address;
        twoKeyAdmin = _twoKeyAdmin;
        twoKeyCommunityTokenPool = _twoKeyCommunityTokenPool;
        tokensReleaseDate = block.timestamp + 10 * (1 years);
        initialized = true;
    }

    /**
     * @notice Function can transfer tokens only after 10 years to community token pool
     * @param amount is the amount of tokens we're sending
     * @dev only two key admin can issue a call to this method
     */
    function transferTokensToCommunityPool(uint amount) public onlyTwoKeyAdmin {
        require(getContractBalance() >= amount);
        require(block.timestamp > tokensReleaseDate);
        super.transferTokens(twoKeyCommunityTokenPool,amount);
    }

}
