pragma solidity ^0.4.24;

contract TwoKeyLockupContract {

    uint tokenDistributionDate;
    uint maxDistributionDateShiftInDays;
    uint tokens;
    address converter;
    address contractor;
    bool changed = false;


    modifier onlyContractor() {
        require(msg.sender == contractor);
        _;
    }
    constructor(uint _tokenDistributionDate, uint _maxDistributionDateShiftInDays, uint _tokens, address _converter, address _contractor) {
        tokenDistributionDate = _tokenDistributionDate;
        maxDistributionDateShiftInDays = _maxDistributionDateShiftInDays;
        tokens = _tokens;
        converter = _converter;
        contractor = _contractor;
    }

    function changeTokenDistributionDate(uint _newDate) public onlyContractor {
        require(changed == false);
        require(_newDate - (maxDistributionDateShiftInDays * (1days)) <= tokenDistributionDate);
        changed = true;
        tokenDistributionDate = _newDate;
    }
    //TODO: Add function to change distribution date, only once
}
