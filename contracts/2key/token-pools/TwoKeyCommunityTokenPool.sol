pragma solidity ^0.4.24;

import "./TokenPool.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TwoKeyCommunityTokenPool is TokenPool {

    uint totalAmount2keys = 200000000;
    uint public constant annualTransferAmount = totalAmount2keys / 10;
    uint startingDate;
    uint transferedDuringYear;

    function setInitialParams(address _twoKeyAdmin) public {
        require(twoKeyAdmin == address(0));
        twoKeyAdmin = _twoKeyAdmin;
        startingDate = block.timestamp;
    }





}
