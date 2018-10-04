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
        converter = _converter;
        converter = _converter;
        converter = _converter;
        contractor = _contractor;
    }

    function changeTokenDistributionDate(uint _newDate) public onlyContractor {
        require(changed == false);
        require(_newDate - (maxDistributionDateShiftInDays * (1 days)) <= tokenDistributionDate);
        changed = true;
        tokenDistributionDate = _newDate;
    }
    //TODO: Add only Converter can transfer tokens from this contract after vesting date

    function transferFungibleAsset(address _assetContractERC20, address _to, uint256 _amount) public onlyContractor returns (bool) {
        require(tokens >= _amount);
        require(block.timestamp > tokenDistributionDate);
            _assetContractERC20.call(
                bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
                _to, _amount
            );
        tokens = tokens - _amount;
        return true;
    }

}
