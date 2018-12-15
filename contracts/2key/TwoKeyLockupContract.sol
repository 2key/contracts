pragma solidity ^0.4.24;

import "../interfaces/IERC20.sol";

contract TwoKeyLockupContract {

    uint bonusTokensVestingStartShiftInDaysFromDistributionDate;
    uint bonusTokensVestingMonths;
    uint tokenDistributionDate;
    uint maxDistributionDateShiftInDays;

    uint public baseTokens;
    uint public bonusTokens;
    uint totalTokensLeftOnContract;
    uint withdrawn = 0;

    address converter;
    address contractor;
    address twoKeyAcquisitionCampaignERC20Address;
    address twoKeyConversionHandler;
    address assetContractERC20;

    bool changed = false;

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

    //TODO: Only converter or contractor can see all this informations
    constructor(
        uint _bonusTokensVestingStartShiftInDaysFromDistributionDate,
        uint _bonusTokensVestingMonths,
        uint _tokenDistributionDate,
        uint _maxDistributionDateShiftInDays,
        uint _baseTokens,
        uint _bonusTokens,
        address _converter,
        address _contractor,
        address _acquisitionCampaignERC20Address,
        address _assetContractERC20
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
        assetContractERC20 = _assetContractERC20;
        totalTokensLeftOnContract = baseTokens + bonusTokens;
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


    /// @notice Function where converter can withdraw his funds
    /// @return true if transfer was successful, otherwise will revert
    /// onlyConverter
    function transferFungibleAsset() public returns (bool) {
        uint unlocked = getAllUnlockedAtTheMoment();
        uint amount = unlocked - withdrawn;
        totalTokensLeftOnContract = totalTokensLeftOnContract - amount;
        withdrawn = withdrawn + amount;
        require(IERC20(assetContractERC20).transfer(msg.sender,amount));
        return true;
    }



    /// @notice This function can only be called by conversion handler and that's when contractor want to cancel his campaign
    /// @param _assetContractERC20 is the asset contract address
    function cancelCampaignAndGetBackTokens(address _assetContractERC20) public onlyTwoKeyConversionHandler {
        require(IERC20(_assetContractERC20).transfer(twoKeyAcquisitionCampaignERC20Address, baseTokens+bonusTokens));
        selfdestruct(twoKeyAcquisitionCampaignERC20Address);
    }

    /// @notice This function will check how much of bonus tokens are unlocked at the moment
    /// @dev this is internal function
    function howMuchBonusUnlocked() internal view returns (uint) {
        uint bonusSplited = bonusTokens / bonusTokensVestingMonths;

        uint counter = 0;
        for(uint i=0; i<bonusTokensVestingMonths; i++) {
            if(tokenDistributionDate + bonusTokensVestingStartShiftInDaysFromDistributionDate + i*(30 days) < block.timestamp) {
                counter++;
            }
        }
        return bonusSplited * counter;
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

    function getTotalTokensLeftOnContract() public view returns (uint) {
        return totalTokensLeftOnContract;
    }

    function getWithdrawn() public view returns (uint) {
        return withdrawn;
    }

    function getAllUnlockedAtTheMoment() public view returns (uint) {
        return isBaseUnlocked() + howMuchBonusUnlocked();
    }

    function getNumberOfVestingMonths() public view returns (uint) {
        return bonusTokensVestingMonths;
    }

    function getInformation() public view returns (uint,uint,uint,uint,uint,uint) {
        uint allUnlockedAtTheMoment = getAllUnlockedAtTheMoment();
        return (baseTokens, bonusTokens, bonusTokensVestingMonths, withdrawn, totalTokensLeftOnContract, allUnlockedAtTheMoment);
    }
}
