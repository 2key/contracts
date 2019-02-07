pragma solidity ^0.4.24;

import "./TokenPool.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TwoKeyLongTermTokenPool is TokenPool {

    uint releaseDate;

    modifier onlyAfterReleaseDate {
        require(block.timestamp > releaseDate);
        _;
    }

    function setInitialParams(address _twoKeyAdmin, address _erc20Address, address [] _maintainers) public {
        require(initialized == false);
        super.setInitialParams(_twoKeyAdmin, _erc20Address, _maintainers);
        releaseDate = block.timestamp + 3 * (1 years);
        initialized = true;
    }

    /**
     * @notice Long term pool will hold the tokens for 3 years after that they can be transfered by TwoKeyAdmin
     * @param _receiver is the receiver of the tokens
     * @param _amount is the amount of the tokens
     */
    function transferTokensFromContract(address _receiver, uint _amount) public onlyTwoKeyAdmin onlyAfterReleaseDate {
        super.transferTokens(_receiver, _amount);
    }

}
