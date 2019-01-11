pragma solidity ^0.4.24;

import "../interfaces/IERC20.sol";

contract TwoKeyLockupContract {

    uint bonusTokensVestingStartShiftInDaysFromDistributionDate;
    uint bonusTokensVestingMonths;
    uint tokenDistributionDate;
    uint maxDistributionDateShiftInDays;

    uint public baseTokens;
    uint public bonusTokens;


    mapping(uint => uint) public tokenUnlockingDate;
    mapping(uint => bool) public isWithdrawn;

    address public converter;
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
        tokenUnlockingDate[0] = tokenDistributionDate; //base tokens
        for(uint i=1 ;i<bonusTokensVestingMonths + 1; i++) {
            tokenUnlockingDate[i] = tokenDistributionDate + i * (30 days); ///bonus tokens
        }
    }

    ///TODO: Comment onlyConverter
    function getLockupSummary() public view returns (uint, uint, uint, uint[], bool[]) {
        uint[] memory dates = new uint[](bonusTokensVestingMonths+1);
        bool[] memory areTokensWithdrawn = new bool[](bonusTokensVestingMonths+1);

        for(uint i=0; i<bonusTokensVestingMonths+1;i++) {
            dates[i] = tokenUnlockingDate[i];
            areTokensWithdrawn[i] = isWithdrawn[i];
        }
        //total = base + bonus
        // monthly bonus = bonus/bonusTokensVestingMonths
        return (baseTokens, bonusTokens, bonusTokensVestingMonths ,dates,areTokensWithdrawn);
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
    /// @return true is if transfer was successful, otherwise will revert
    /// onlyConverter
    function withdrawTokens(uint part) public onlyConverter returns (bool) {
        require(isWithdrawn[part] == false && part < bonusTokensVestingMonths+1 && block.timestamp > tokenUnlockingDate[part]);
        uint amount;
        if(part == 0) {
            amount = baseTokens;
        } else {
            amount = bonusTokens / bonusTokensVestingMonths;
        }
        isWithdrawn[part] = true;
        require(IERC20(assetContractERC20).transfer(msg.sender,amount));
        return true;
    }



    /// @notice This function can only be called by conversion handler and that's when contractor want to cancel his campaign
    /// @param _assetContractERC20 is the asset contract address
    function cancelCampaignAndGetBackTokens(address _assetContractERC20) public onlyTwoKeyConversionHandler {
        require(IERC20(_assetContractERC20).transfer(twoKeyAcquisitionCampaignERC20Address, baseTokens+bonusTokens));
        selfdestruct(twoKeyAcquisitionCampaignERC20Address);
    }

}