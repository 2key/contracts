pragma solidity ^0.4.24;

contract TwoKeyLockupContract {

    uint bonusTokensVestingStartShiftInDaysFromDistributionDate;
    uint bonusTokensVestingMonths;
    uint tokenDistributionDate;
    uint maxDistributionDateShiftInDays;
    uint public baseTokens;
    uint public bonusTokens;

    uint totalTokens;

    bool changed = false;

    address converter;
    address contractor;
    address twoKeyAcquisitionCampaignERC20Address;
    address twoKeyConversionHandler;


    modifier onlyContractor() {
        require(msg.sender == contractor);
        _;
    }

    modifier onlyConverter() {
        require(msg.sender == converter);
        _;
    }

    modifier onlyTwoKeyConversionHandler() {
        require(msg.sender == twoKeyConversionHandler);
        _;
    }


    constructor(
        uint _bonusTokensVestingStartShiftInDaysFromDistributionDate,
        uint _bonusTokensVestingMonths,
        uint _tokenDistributionDate,
        uint _maxDistributionDateShiftInDays,
        uint _baseTokens,
        uint _bonusTokens,
        address _converter,
        address _contractor,
        address _acquisitionCampaignERC20Address
    ) public {
        bonusTokensVestingStartShiftInDaysFromDistributionDate = _bonusTokensVestingStartShiftInDaysFromDistributionDate;
        bonusTokensVestingMonths = _bonusTokensVestingMonths;
        tokenDistributionDate = _tokenDistributionDate;
        maxDistributionDateShiftInDays = _maxDistributionDateShiftInDays;
        baseTokens = _baseTokens;
        bonusTokens = _bonusTokens;
        converter = _converter;
        contractor = _contractor;
        twoKeyAcquisitionCampaignERC20Address = _acquisitionCampaignERC20Address;
        twoKeyConversionHandler = msg.sender;

        totalTokens = baseTokens + bonusTokens;
    }


    /// @notice Function to change token distribution date
    /// @dev only contractor can issue calls to this method, and token distribution date can be changed only once
    /// @param _newDate is new token distribution date we'd like to set
    function changeTokenDistributionDate(uint _newDate) public onlyContractor {
        require(changed == false);
        require(_newDate - (maxDistributionDateShiftInDays * (1 days)) <= tokenDistributionDate);
        require(now < tokenDistributionDate);
        changed = true;
        tokenDistributionDate = _newDate;
    }

    function isBaseUnlocked() public view returns (uint) {
        if(tokenDistributionDate > block.timestamp) {
            return baseTokens;
        }
        return 0;
    }

    function getBaseTokensAmount() public view returns (uint) {
        return baseTokens;
    }

    function getTotalBonus() public view returns (uint) {
        return bonusTokens;
    }

    function getMonthlyBonus() public view returns (uint) {
        return bonusTokens / bonusTokensVestingMonths;
    }

    function getBalaceOfContract() public view returns (uint) {
        return totalTokens;
    }


    function howMuchBonusUnlocked() public view returns (uint) {
        uint bonusSplited = bonusTokens / bonusTokensVestingMonths;

        uint counter = 0;
        for(uint i=0; i<bonusTokensVestingMonths; i++) {
            if(tokenDistributionDate + bonusTokensVestingStartShiftInDaysFromDistributionDate + i*(30 days) > block.timestamp) {
                counter++;
            }
        }
        return bonusSplited * counter;
    }

    /// @notice Function where converter can withdraw his funds
    /// @param _assetContractERC20 is the asset contract address
    /// @param _amount is the amount of the tokens he'd like to get
    /// @return true if transfer was successful, otherwise will revert
    function transferFungibleAsset(address _assetContractERC20, uint256 _amount) public onlyConverter returns (bool) {
        require(totalTokens >= _amount, 'Trying to withdraw more tokens then existing in contract');
        uint unlocked = isBaseUnlocked() + howMuchBonusUnlocked();
        require(_amount <= unlocked, 'Trying to withdraw more than unlocked');
        require(block.timestamp > tokenDistributionDate);
        _assetContractERC20.call(
            bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
            msg.sender, _amount
        );
        totalTokens = totalTokens - _amount;
        return true;
    }



    /// @notice This function can only be called by conversion handler and that's when contractor want to cancel his campaign
    /// @param _assetContractERC20 is the asset contract address
    function cancelCampaignAndGetBackTokens(address _assetContractERC20) public onlyTwoKeyConversionHandler {
        _assetContractERC20.call( //Send the tokens back to campaign
            bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
            twoKeyAcquisitionCampaignERC20Address, baseTokens+bonusTokens
        );
        selfdestruct(twoKeyAcquisitionCampaignERC20Address);
    }
}
