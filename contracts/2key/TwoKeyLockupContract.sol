pragma solidity ^0.4.24;

contract TwoKeyLockupContract {

    uint tokenDistributionDate;
    uint maxDistributionDateShiftInDays;
    uint baseTokens;
    uint converter;
    uint contractor;


    constructor(uint _tokenDitributionDate, uint _maxDistributionDateShiftInDays, uint _baseTokens, uint _converter, uint _contractor) {
        tokenDistributionDate = _tokenDistributionDate;
        maxDistributionDateShiftInDays = _maxDistributionDateShiftInDays;
        baseTokens = _baseTokens;
        converter = _converter;
        contractor = _contractor;
    }

}
