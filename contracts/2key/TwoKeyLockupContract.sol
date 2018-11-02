pragma solidity ^0.4.24;

contract TwoKeyLockupContract {

    address twoKeyConversionHandler;
    uint tokenDistributionDate;
    uint maxDistributionDateShiftInDays;
    uint tokens;
    address converter;
    address contractor;
    bool changed = false;
    address twoKeyAcquisitionCampaignERC20Address;


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


    constructor(uint _tokenDistributionDate, uint _maxDistributionDateShiftInDays, uint _tokens, address _converter, address _contractor, address _acquisitionCampaignERC20Address) public {
        twoKeyConversionHandler = msg.sender;
        tokenDistributionDate = _tokenDistributionDate;
        maxDistributionDateShiftInDays = _maxDistributionDateShiftInDays;
        tokens = _tokens;
        converter = _converter;
        contractor = _contractor;
        twoKeyAcquisitionCampaignERC20Address = _acquisitionCampaignERC20Address;
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
    /// @param _assetContractERC20 is the asset contract address
    /// @param _amount is the amount of the tokens he'd like to get
    /// @return true if transfer was successful, otherwise will revert
    function transferFungibleAsset(address _assetContractERC20, uint256 _amount) public onlyConverter returns (bool) {
        require(tokens >= _amount);
        require(block.timestamp > tokenDistributionDate);
        _assetContractERC20.call(
            bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
            msg.sender, _amount
        );
        tokens = tokens - _amount;
        return true;
    }

    /// @notice Function where converter can check if his tokens are unlocked
    /// @return true if tokens are unlocked
    function areTokensUnlocked() public view onlyConverter returns (bool) {
        if(block.timestamp > tokenDistributionDate) {
            return true;
        }
        return false;
    }


    /// @notice This function can only be called by conversion handler and that's when contractor want to cancel his campaign
    /// @param _assetContractERC20 is the asset contract address
    function cancelCampaignAndGetBackTokens(address _assetContractERC20) public onlyTwoKeyConversionHandler {
        _assetContractERC20.call( //Send the tokens back to campaign
            bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
            twoKeyAcquisitionCampaignERC20Address, tokens
        );
        selfdestruct(twoKeyAcquisitionCampaignERC20Address);
    }

}
