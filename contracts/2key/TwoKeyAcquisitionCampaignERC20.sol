pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./TwoKeyCampaignARC.sol";
import "./TwoKeyEventSource.sol";
import "./TwoKeyConversionHandler.sol";
import "./TwoKeyEconomy.sol";
import "../interfaces/IERC20.sol";
import "./Utils.sol";
import "./TwoKeyTypes.sol";


/// @author Nikola Madjarevic
/// Contract which will represent campaign for the fungible assets
contract TwoKeyAcquisitionCampaignERC20 is TwoKeyCampaignARC, Utils, TwoKeyTypes {

    // Using safemath to avoid overflows during math operations
    using SafeMath for uint256;


    // ==============================================================================================================
    // =====================================TWO KEY ACQUISITION CAMPAIGN EVENTS======================================
    // ==============================================================================================================
    event UpdatedPublicMetaHash(uint timestamp, string value);
    event UpdatedData(uint timestamp, uint value, string action);
    event Fulfilled(address indexed to, uint256 units);
    event Rewarded(address indexed to, uint256 amount);
    event Expired(address indexed _contract);
    event ReceivedEther(address _sender, uint value);

    // ==============================================================================================================
    // =============================TWO KEY ACQUISITION CAMPAIGN STATE VARIABLES=====================================
    // ==============================================================================================================


    // Mapping representing how much are cuts in percent(0-100) for referrer address
    mapping(address => uint256) referrer2cut;

    /// Amount converter put to the contract in Ether
    mapping(address => uint) balancesConvertersETH;

    mapping(address => uint) balances;

    // Number of units (ERC20 tokens) bought
    mapping(address => uint256) public units;

    // the 2key link generated by the owner of this contract contains a secret which is a private key,
    // this is the public part of this secret
    // First address is person who started TwoKeyLink (convertor,contractor, influencer)
    mapping(address => address) public publicLinkKey;

    // Balance will represent how many that tokens (erc20) we have on our Campaign
    uint campaignInventoryUnitsBalance;

    // Asset contract is address of ERC20 inventory
    address assetContractERC20;

    // TwoKeyEconomy contract (ERC20)
    TwoKeyEconomy twoKeyEconomy;

    // Contract representing whitelisted referrers and converters
    TwoKeyConversionHandler conversionHandler;


    uint256 contractorBalance;
    uint256 contractorTotalProceeds;

    // There's single price for the unit ERC20 (Should be in WEI)
    uint256 pricePerUnitInETHWei;

    // Rate of conversion from TwoKey to ETC
    uint256 public rate = 1;

    // Time when campaign start
    uint256 campaignStartTime;

    // Time when campaign ends
    uint256 campaignEndTime;

    // How long convertor can be pending before it will be automatically rejected and funds will be returned to convertor (hours)
    uint256 expiryConversionInHours;

    // How long will hold asset in escrow
    uint256 moderatorFeePercentage;

    // Ipfs hash of json campaign object
    string public publicMetaHash;

    // Ipfs hash of json sensitive (contractor) information
    string privateMetaHash;

    // maxRefferalRewardPercent is actually bonus percentage in ETH
    uint256 public maxReferralRewardPercent;

    //translates to discount - we can add this to constructor
    uint maxConverterBonusPercent;

    // Minimal amount of ETH that can be paid by converter to create conversion
    uint minContributionETH;

    // Maximal amount of ETH that can be paid by converter to create conversion
    uint maxContributionETH;

    uint unit_decimals;
    string symbol;


    // ==============================================================================================================
    // ============================ TWO KEY ACQUISITION CAMPAIGN MODIFIERS ==========================================
    // ==============================================================================================================


    /// @notice Modifier which is going to check if current time is between opening-closing campaign time
    modifier isOngoing() {
        require(block.timestamp >= campaignStartTime && block.timestamp <= campaignEndTime);
        _;
    }

    modifier onlyTwoKeyConversionHandler() {
        require(msg.sender == address(conversionHandler));
        _;
    }




    // ==============================================================================================================
    // =============================TWO KEY ACQUISITION CAMPAIGN CONSTRUCTOR=========================================
    // ==============================================================================================================

    constructor(address _twoKeyEventSource, address _twoKeyEconomy,
        address _conversionHandler,
        address _moderator, address _assetContractERC20, uint _campaignStartTime, uint _campaignEndTime,
        uint _expiryConversion, uint _moderatorFeePercentage, uint _maxReferralRewardPercent, uint _maxConverterBonusPercent,
        uint _pricePerUnitInETH, uint _minContributionETH, uint _maxContributionETH,
        uint _conversionQuota)
        TwoKeyCampaignARC(_twoKeyEventSource, _conversionQuota) StandardToken()
    public {
        require(_twoKeyEconomy != address(0));
        require(_assetContractERC20 != address(0));
        require(_maxReferralRewardPercent > 0);
        require(_conversionHandler != address(0));

        contractor = msg.sender;
        twoKeyEconomy = TwoKeyEconomy(_twoKeyEconomy);
        conversionHandler = TwoKeyConversionHandler(_conversionHandler);
        moderator = _moderator;
        assetContractERC20 = _assetContractERC20;
        campaignStartTime = _campaignStartTime;
        campaignEndTime = _campaignEndTime;
        expiryConversionInHours = _expiryConversion;
        moderatorFeePercentage = _moderatorFeePercentage;
        maxReferralRewardPercent = _maxReferralRewardPercent;
        maxConverterBonusPercent = _maxConverterBonusPercent;

        pricePerUnitInETHWei = _pricePerUnitInETH;
        minContributionETH = _minContributionETH;
        maxContributionETH = _maxContributionETH;

        setERC20Attributes();
        conversionHandler.setTwoKeyAcquisitionCampaignERC20(address(this), _moderator, contractor, _assetContractERC20, symbol);

        // Emit event that TwoKeyCampaign is created
        twoKeyEventSource.created(address(this), contractor);

    }


    /// Maybe remove function and just assign this 2 methods in constructor
    function setERC20Attributes() private {
        unit_decimals = IERC20(assetContractERC20).decimals();
        symbol = IERC20(assetContractERC20).symbol();
    }

    /**
     * given the total payout, calculates the moderator fee
     * @param  _conversionAmountETHWei total payout for escrow
     * @return moderator fee
     */
    function calculateModeratorFee(uint256 _conversionAmountETHWei) internal view returns (uint256)  {
        if (moderatorFeePercentage > 0) {// send the fee to moderator
            uint256 fee = _conversionAmountETHWei.mul(moderatorFeePercentage).div(100).div(10 ** unit_decimals);
            return fee;
        }
        return 0;
    }

    /// @notice Method to add fungible asset to our contract
    /// @dev When user calls this method, he just says the actual amount of ERC20 he'd like to transfer to us
    /// @param _amount is the amount of ERC20 contract he'd like to give us
    /// @return true if successful, otherwise transaction will revert
    function addUnitsToInventory(uint256 _amount) public returns (bool) {
        require(
            assetContractERC20.call(
                bytes4(keccak256("transferFrom(address,address,uint256)")),
                msg.sender,
                address(this),
                _amount
            )
        );
        campaignInventoryUnitsBalance += _amount;
        return true;
    }


    function cancelledEscrow(address converter, uint256 _amount) internal {
        uint contractorProceeds = conversionHandler.supportForCanceledEscrow(converter);
        addUnitsToInventory(_amount);
        require(twoKeyEconomy.transfer(converter, contractorProceeds.mul(rate)));
    }


    function cancelAssetTwoKey(address _converter, string _assetName, address _assetContract, uint256 _amount) public returns (bool) {
        conversionHandler.supportForCancelAssetTwoKey(_converter);
        cancelledEscrow(_converter, _amount);
        twoKeyEventSource.cancelled(address(this), _converter, _assetName, _assetContract, _amount, CampaignType.CPA_FUNGIBLE);
        return true;
    }


    function expireEscrow(address _converter, uint256 _amount) public returns (bool) {
        conversionHandler.supportForExpireEscrow(_converter);
        cancelledEscrow(_converter, _amount);
        emit Expired(address(this));
        return true;
    }

    /// Is there a need to put assetContract as parameter , address _assetContract also assetName
    /// Also, this function don't need to be payable, we're sending two key tokens here, not eth
    /// (It was payable)
    //    function buyFromWithTwoKey(address _from, string _assetName, uint256 _amount) public {
    //        fulfillFungibleTwoKeyToken(_from, _assetName, _amount);
    //    }

    // @notice Function where an influencer that wishes to cash an _amount of 2key from the campaign can do it
    function redeemTwoKeyToken(uint256 _amount) public {
        require(referrerBalances2KEY[msg.sender] >= _amount && _amount > 0);
        referrerBalances2KEY[msg.sender] = referrerBalances2KEY[msg.sender].sub(_amount);
        twoKeyEconomy.transferFrom(this, msg.sender, _amount);
    }

    function joinAndShareARC(bytes signature, address receiver) public {
        distributeArcsBasedOnSignature(signature);
        transferFrom(msg.sender, receiver, 1);
    }

    /// At the beginning only contractor can call this method bcs he is the only one who has arcs
    function setPublicLinkKey(address _public_link_key) public {
        // Here we're requiring that msg.sender has arcs
        require(balanceOf(msg.sender) > 0,'no ARCs');

        // Here we're checking that msg.sender have not previously joined
        require(publicLinkKey[msg.sender] == address(0),'public link key already defined');
        publicLinkKey[msg.sender] = _public_link_key;
    }

    function setCut(uint256 cut) private {
        // the sender sets what is the percentage of the bounty s/he will receive when acting as an influencer
        // the value 255 is used to signal equal partition with other influencers
        // A sender can set the value only once in a contract
        require(cut <= 100 || cut == 255);
        require(referrer2cut[msg.sender] == 0);
        if (cut <= 100) {
            cut++;
        }
        referrer2cut[msg.sender] = cut;
    }

    /// @notice Method distributes arcs based on signature
    /// @param sig is the signature generated on frontend side
    function distributeArcsBasedOnSignature(bytes sig) public {
        // move ARCs based on signature information

        // if version=1, with_cut is true then sig also include the cut (percentage) each influencer takes from the bounty
        // the cut is stored in influencer2cut
        uint idx = 0;
        //    uint8 version;
        //    if (idx+1 <= sig.length) {
        //      idx += 1;
        //      assembly
        //      {
        //        version := mload(add(sig, idx))
        //      }
        //    }
        //    require(version < 2);
        //    bool with_cut = false;
        //    if (version == 1) {
        //      with_cut = true;
        //    }

        address old_address;
        if (idx+20 <= sig.length) {
            idx += 20;
            assembly
            {
                old_address := mload(add(sig, idx))
            }
        }

        address old_public_link_key = publicLinkKey[old_address];
        require(old_public_link_key != address(0),'no public link key');

        while (idx + 65 <= sig.length) {
            // The signature format is a compact form of:
            //   {bytes32 r}{bytes32 s}{uint8 v}
            // Compact means, uint8 is not padded to 32 bytes.
            idx += 32;
            bytes32 r;
            assembly
            {
                r := mload(add(sig, idx))
            }

            idx += 32;
            bytes32 s;
            assembly
            {
                s := mload(add(sig, idx))
            }

            idx += 1;
            uint8 v;
            assembly
            {
                v := mload(add(sig, idx))

            }
            //TODO: copy updated code from Udi (validate v value)

            // idx was increased by 65

            bytes32 hash;
            address new_public_key;
            address new_address;
            //      if (idx + (with_cut ? 41 : 40) < sig.length) {
            if (idx + 41 <= sig.length) {  // its  a < and not a <= because we dont want this to be the final iteration for the converter
                uint8 bounty_cut;
                //        if (with_cut)
                {
                    idx += 1;
                    assembly
                    {
                        bounty_cut := mload(add(sig, idx))
                    }
                    require(bounty_cut > 0,'bounty should be 1..101 or 255');  // 0 and 255 are used to indicate default (equal part) behaviour
                }

                idx += 20;
                assembly
                {
                    new_address := mload(add(sig, idx))
                }

                idx += 20;
                assembly
                {
                    new_public_key := mload(add(sig, idx))
                }

                //        if (with_cut)
                //        {
                //          require(bounty_cut > 0);

                // update (only once) the cut used by each influencer
                // we will need this in case one of the influencers will want to start his own off-chain link
                if (referrer2cut[new_address] == 0) {
                    referrer2cut[new_address] = uint256(bounty_cut);
                } else {
                    require(referrer2cut[new_address] == uint256(bounty_cut),'bounty cut can not be modified');
                }

                // update (only once) the public address used by each influencer
                // we will need this in case one of the influencers will want to start his own off-chain link
                if (publicLinkKey[new_address] == 0) {
                    publicLinkKey[new_address] = new_public_key;
                } else {
                    require(publicLinkKey[new_address] == new_public_key,'public key can not be modified');
                }

                hash = keccak256(abi.encodePacked(bounty_cut, new_public_key, new_address));
                //        }

                // check if we exactly reached the end of the signature. this can only happen if the signature
                // was generated with free_take_join and in this case the last part of the signature must have been
                // generated by the caller of this method
                if (idx == sig.length) {
                    require(new_address == msg.sender,'only the last in the link can call transferSig');
                }
            } else {
                // handle short signatures generated with free_take
                // signed message for the last step is the address of the converter
                new_address = msg.sender;
                hash = keccak256(abi.encodePacked(new_address));
            }
            // assume users can take ARCs only once... this could be changed
            if (received_from[new_address] == 0) {
                transferFrom(old_address, new_address, 1);
            } else {
                require(received_from[new_address] == old_address,'only tree ARCs allowed');
            }

            // check if we received a valid signature
            address signer = ecrecover(hash, v, r, s);
            require (signer == old_public_link_key, 'illegal signature');
            old_public_link_key = new_public_key;
            old_address = new_address;
        }
        require(idx == sig.length,'illegal message size');
    }

    //******************************************************
    //TODO: andrii if user wants to convert with metamask, they need to choose metamask before you call create their sig and call this function
    function joinAndConvert(bytes signature) public payable {
        require(msg.value >= minContributionETH);
        require(msg.value <= maxContributionETH);
        distributeArcsBasedOnSignature(signature);
        createConversion(msg.value, msg.sender);
    }

    function convert() public payable  {
        require(msg.value >= minContributionETH);
        require(msg.value <= maxContributionETH);
        require(received_from[msg.sender] != address(0));
        createConversion(msg.value, msg.sender);
    }

    //TODO: for paying with external address, the user needs to transfer an ARC to the external address, and then we can call the public default payable
    function() external payable {
        require(msg.value >= minContributionETH);
        require(msg.value <= maxContributionETH);
        require(balanceOf(msg.sender) > 0);
        createConversion(msg.value, msg.sender);
    }

    //******************************************************
    //(2) CONVERSION 1st STEP

    /// @notice Function to create conversion
    /// @param conversionAmountETHWei is actually the msg.value (amount of ether)
    /// @param converterAddress is actually the msg.sender (Address of one who's executing conversion)
    /// isOngoing
    function createConversion(uint conversionAmountETHWei, address converterAddress) {
        uint baseTokensForConverterUnits;
        uint bonusTokensForConverterUnits;

        (baseTokensForConverterUnits, bonusTokensForConverterUnits) = getEstimatedTokenAmount(conversionAmountETHWei);

        uint totalTokensForConverterUnits = baseTokensForConverterUnits + bonusTokensForConverterUnits;

        uint256 _total_units = getInventoryBalance();
        require(_total_units >= totalTokensForConverterUnits);

        units[converterAddress] = units[converterAddress].add(totalTokensForConverterUnits);

        uint256 maxReferralRewardETHWei = conversionAmountETHWei.mul(maxReferralRewardPercent).div(100);
        uint256 moderatorFeeETHWei = calculateModeratorFee(conversionAmountETHWei);

        uint256 contractorProceedsETHWei = conversionAmountETHWei - maxReferralRewardETHWei - moderatorFeeETHWei;

        conversionHandler.supportForCreateConversion(contractor, contractorProceedsETHWei, converterAddress,
            conversionAmountETHWei, maxReferralRewardETHWei, moderatorFeeETHWei,
            baseTokensForConverterUnits,bonusTokensForConverterUnits,
            expiryConversionInHours);

//        emit ReceivedEther(converterAddress, conversionAmountETHWei);
    }


    function updateRefchainRewards(uint256 _maxReferralRewardETHWei, address _converter) public onlyTwoKeyConversionHandler {
        require(_maxReferralRewardETHWei > 0);
        address converter = _converter;
        address[] memory influencers = getReferrers(converter);

        uint256 total_bounty = 0;
        for (uint i = 0; i < influencers.length; i++) {
            uint256 b;
            if (i == influencers.length - 1) {// if its the last influencer then all the bounty goes to it.
                b = _maxReferralRewardETHWei;
            }
            else {
                uint256 cut = referrer2cut[influencers[i]];
                if (cut > 0 && cut <= 101) {
                    b = _maxReferralRewardETHWei.mul(cut.sub(1)).div(100);
                } else {// cut == 0 or 255 indicates equal particine of the bounty
                    b = _maxReferralRewardETHWei.div(influencers.length - i);
                }
            }
            referrerBalancesETHWei[influencers[i]] = referrerBalancesETHWei[influencers[i]].add(b);
            //Updating total earning
            referrerTotalEarnings2KEY[influencers[i]] = referrerTotalEarnings2KEY[influencers[i]].add(b);
            emit Rewarded(influencers[i], b);
            total_bounty = total_bounty.add(b);
            _maxReferralRewardETHWei = _maxReferralRewardETHWei.sub(b);
        }

        contractorBalance = contractorBalance.add(_maxReferralRewardETHWei);
        contractorTotalProceeds = contractorTotalProceeds.add(_maxReferralRewardETHWei);
//        emit Fulfilled(customer, units[customer]);
    }






    /// Is there a need to put assetContract as parameter , address _assetContract also assetName
    /// Also, this function don't need to be payable, we're sending two key tokens here, not eth
    /// (It was payable)
    //    function buyFromWithTwoKey(address _from, string _assetName, uint256 _amount) public {
    //        fulfillFungibleTwoKeyToken(_from, _assetName, _amount);
    //    }




    /// @notice Move some amount of ERC20 from our campaignInventoryUnitsBalance to someone
    /// @dev internal function
    /// @param _to address we're sending the amount of ERC20
    /// @param _amount is the amount of ERC20's we're going to transfer
    /// @return true if successful, otherwise reverts
    function moveFungibleAsset(address _to, uint256 _amount) public onlyTwoKeyConversionHandler returns (bool) {
        require(campaignInventoryUnitsBalance >= _amount);
        require(
            assetContractERC20.call(
                bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
                _to, _amount
            )
        );
        campaignInventoryUnitsBalance = campaignInventoryUnitsBalance - _amount;
        return true;
    }

    // transfer an amount of erc20 from our catalogue to someone
    // This should be called when conversion is executed

    /// @notice Function which will transfer fungible assets from contract to someone
    /// @param _to is the address we're sending the fungible assets
    /// @param _amount is the amount of ERC20 we're going to transfer
    /// @return true if trasaction completes otherwise transaction will revert
    function transferFungibleAsset(address _to, uint256 _amount) internal returns (bool) {
        return moveFungibleAsset(_to, _amount);
    }




    // ==============================================================================================================
    // =================TWO KEY ACQUISITION CAMPAIGN GETTERS, SETTERS AND HELPER METHODS=============================
    // ==============================================================================================================


    /// @notice Function to check how much eth has been sent to contract from address
    /// @param _from is the address we'd like to check balance
    /// @return amount of ether sent to contract from the specified address
    function getAmountAddressSent(address _from) public view returns (uint) {
        return balancesConvertersETH[_from];
    }

    /// @notice Function to check contract balance of specified ERC20 tokens
    /// @return balance
    function getContractBalance() public view returns (uint) {
        return campaignInventoryUnitsBalance;
    }


    /// @notice Function to return constantss
    function getConstantInfo() public view returns (uint256, uint256, uint256, uint256) {
        return (pricePerUnitInETHWei, maxReferralRewardPercent, conversionQuota, unit_decimals);
    }

    /// @notice Function which acts like getter for all cuts in array
    /// @param last_influencer is the last influencer
    /// @return array of integers containing cuts respectively
    function getReferrerCuts(address last_influencer) public view returns (uint256[]) {
        address[] memory influencers = getReferrers(last_influencer);
        uint256[] memory cuts = new uint256[](influencers.length + 1);
        for (uint i = 0; i < influencers.length; i++) {
            address influencer = influencers[i];
            cuts[i] = referrer2cut[influencer];
        }
        cuts[influencers.length] = referrer2cut[last_influencer];
        return cuts;
    }

    /// @notice Function which returns value of maxReferralRewardPercent
    /// @return value of maxReferralRewardPercent as uint256
    function getMaxReferralRewardPercent() public view returns (uint256) {
        return maxReferralRewardPercent;
    }

    /// @notice This is acting as a getter for referrer2cut
    /// @dev Transaction will revert if msg.sender is not present in mapping
    /// @return cut value / otherwise reverts
    function getReferrerCut() public view returns (uint256) {
        require(referrer2cut[msg.sender] != 0);
        return referrer2cut[msg.sender] - 1;
    }

    /// @notice Function to check balance of the ERC20 inventory (view - no gas needed to call this function)
    /// @dev we're using Utils contract and fetching the balance of this contract address
    /// @return balance value as uint
    function getInventoryBalance() public view returns (uint) {
        uint balance = Utils.call_return(assetContractERC20, "balanceOf(address)", uint(this));
        return balance;
    }

    /// @notice Function which will check the balance and automatically update the balance in our contract regarding balance response
    /// @return balance of ERC20 we have in our contract
    function getAndUpdateInventoryBalance() public returns (uint) {
        uint balance = getInventoryBalance();
        campaignInventoryUnitsBalance = balance;
        return balance;
    }

    /// @notice Function which will calculate the base amount, bonus amount
    /// @param conversionAmountETHWei is amount of eth in conversion
    /// @return tuple containing (base,bonus)
    function getEstimatedTokenAmount(uint conversionAmountETHWei) public view returns (uint, uint) {
        uint baseTokensForConverterUnits = conversionAmountETHWei.mul(10 ** unit_decimals).div(pricePerUnitInETHWei);
        uint bonusTokensForConverterUnits = baseTokensForConverterUnits.mul(maxConverterBonusPercent).div(100).div(10 ** unit_decimals);
        return (baseTokensForConverterUnits, bonusTokensForConverterUnits);
    }

    /// @notice View function - contractor getter
    /// @return address of contractor
    function getContractorAddress() public view returns (address) {
        return contractor;
    }


    /// @notice Setter for privateMetaHash
    /// @dev only Contractor can call this method, otherwise function will revert
    /// @param _privateMetaHash is string representation of private metadata hash
    function setPrivateMetaHash(string _privateMetaHash) public onlyContractor {
        privateMetaHash = _privateMetaHash;
    }

    /// @notice Getter for privateMetaHash
    /// @dev only Contractor can call this method, otherwise function will revert
    /// @return string representation of private metadata hash
    function getPrivateMetaHash() public view onlyContractor returns (string) {
        return privateMetaHash;
    }

    /*
      ================================== PUT /campaign ======================================
    */

    /// @notice Option to update MinContributionETH
    /// @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
    /// @param value is the new value we are going to set for minContributionETH
    function updateMinContributionETH(uint value) public onlyContractor {
        minContributionETH = value;
        twoKeyEventSource.updatedData(block.timestamp, value, "Updated maxContribution");
    }

    /// @notice Option to update maxContributionETH
    /// @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
    /// @param value is the new maxContribution value
    function updateMaxContributionETH(uint value) public onlyContractor {
        maxContributionETH = value;
        twoKeyEventSource.updatedData(block.timestamp, value, "Updated maxContribution");
    }

    /// @notice Option to update maxReferralRewardPercent
    /// @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
    /// @param value is the new referral percent value
    function updateMaxReferralRewardPercent(uint value) public onlyContractor {
        maxReferralRewardPercent = value;
        twoKeyEventSource.updatedData(block.timestamp, value, "Updated maxReferralRewardPercent");
    }

    /// @notice Option to update /set publicMetaHash
    /// @dev only Contractor can call this function, otherwise it will revert - emits Event when set/updated
    /// @param value is the value for the publicMetaHash
    function updateOrSetIpfsHashPublicMeta(string value) public onlyContractor {
        publicMetaHash = value;
        twoKeyEventSource.updatedPublicMetaHash(block.timestamp, value);
    }

    /// @notice Option to update contractor proceeds
    /// @dev can be called only from TwoKeyConversionHandler contract
    /// @param value it the value we'd like to add to total contractor proceeds and contractor balance
    function updateContractorProceeds(uint value) public onlyTwoKeyConversionHandler {
        contractorTotalProceeds.add(value);
        contractorBalance.add(value);
    }

    /// @notice getter for address of conversion handler
    /// @return address representing conversionHandler contract
    function getTwoKeyConversionHandlerAddress() public view returns (address) {
        return conversionHandler;
    }

    function getAddressJoinedStatus() public view returns (bool) {
        if(msg.sender == address(contractor) || msg.sender == address(moderator) || received_from[msg.sender] != address(0)
            || balanceOf(msg.sender) > 0 || publicLinkKey[msg.sender] != address(0)) {
            return true;
        }
        return false;
    }

    function sendBackEthWhenConversionCancelled(address _cancelledConverter, uint _conversionAmount) public onlyTwoKeyConversionHandler {
        _cancelledConverter.transfer(_conversionAmount);
    }
}
