pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./TwoKeyCampaignARC.sol";
import "./TwoKeyEventSource.sol";
import "./TwoKeyConversionHandler.sol";
import "../interfaces/IERC20.sol";
import "./TwoKeyTypes.sol";
import "./Call.sol";

/*
    TODO: Payouts for referrers and moderators in TwoKey
    TODO: Payout for contractor Eth
    TODO: Payout for converter Eth
    TODO: Staking mechanism getting 2key for ether
    We're storing all balances on contract, and we should just make the method where anyone can withdraw his funds

    If withdraw is in ETHER, then we'll do basic transfer
    Otherwise we'll send tokens from economy to the user and delete his balances
*/

/// @author Nikola Madjarevic
/// Contract which will represent campaign for the fungible assets
contract TwoKeyAcquisitionCampaignERC20 is TwoKeyCampaignARC, TwoKeyTypes {

    using Call for *;

    event Rewarded(address indexed to, uint256 amount);
    event Expired(address indexed _contract);

    TwoKeyConversionHandler conversionHandler;

    mapping(address => uint256) referrer2cut; // Mapping representing how much are cuts in percent(0-100) for referrer address
    mapping(address => uint256) internal referrerBalances2KEY; // balance of TwoKeyToken for each influencer that they can withdraw
    mapping(address => uint256) internal referrerBalancesETHWei; // balance of EthWei for each influencer that he can withdraw
    mapping(address => uint256) internal referrerTotalEarnings2KEY; // Total earnings for referrers
    mapping(address => uint) balancesConvertersETH; // Amount converter put to the contract in Ether
    mapping(address => uint) balances;
    mapping(address => uint256) public units; // Number of units (ERC20 tokens) bought
    mapping(address => address) public publicLinkKey; // Public link key can generate only somebody who has ARCs


    uint campaignInventoryUnitsBalance; // Balance will represent how many that tokens (erc20) we have on our Campaign
    address assetContractERC20; // Asset contract is address of ERC20 inventory
    address twoKeyEconomy; // TwoKeyEconomy contract (ERC20)
    uint256 contractorBalance;
    uint256 contractorTotalProceeds;
    uint256 pricePerUnitInETHWei; // There's single price for the unit ERC20 (Should be in WEI)
    uint256 campaignStartTime; // Time when campaign start
    uint256 campaignEndTime; // Time when campaign ends
    uint256 expiryConversionInHours; // How long convertor can be pending before it will be automatically rejected and funds will be returned to convertor (hours)
    uint256 moderatorFeePercentage; // How long will hold asset in escrow
    string public publicMetaHash; // Ipfs hash of json campaign object
    string privateMetaHash; // Ipfs hash of json sensitive (contractor) information
    uint256 public maxReferralRewardPercent; // maxRefferalRewardPercent is actually bonus percentage in ETH
    uint maxConverterBonusPercent; //translates to discount - we can add this to constructor
    uint minContributionETH; // Minimal amount of ETH that can be paid by converter to create conversion
    uint maxContributionETH; // Maximal amount of ETH that can be paid by converter to create conversion
    uint unit_decimals; // ERC20 selling data
    string symbol; // ERC20 selling data
    bool withdrawApproved = false; // Until contractor set this to be true, no one can withdraw funds etc.
    bool canceled = false; // This means if contractor cancel everything


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

    constructor(
        address _twoKeyEventSource,
        address _twoKeyEconomy,
        address _conversionHandler,
        address _moderator,
        address _assetContractERC20,
        uint _campaignStartTime,
        uint _campaignEndTime,
        uint _expiryConversion,
        uint _moderatorFeePercentage,
        uint _maxReferralRewardPercent,
        uint _maxConverterBonusPercent,
        uint _pricePerUnitInETH,
        uint _minContributionETH,
        uint _maxContributionETH,
        uint _conversionQuota
    )
    TwoKeyCampaignARC(
        _twoKeyEventSource,
            _conversionQuota
    ) StandardToken()
    public {
        require(_twoKeyEconomy != address(0));
        require(_assetContractERC20 != address(0));
        require(_maxReferralRewardPercent > 0);
        require(_conversionHandler != address(0));

        contractor = msg.sender;
        twoKeyEconomy = _twoKeyEconomy;
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
        unit_decimals = IERC20(assetContractERC20).decimals();
        symbol = IERC20(assetContractERC20).symbol();
        conversionHandler.setTwoKeyAcquisitionCampaignERC20(address(this), _moderator, contractor, _assetContractERC20, symbol);
        twoKeyEventSource.created(address(this), contractor);
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


    /// At the beginning only contractor can call this method bcs he is the only one who has arcs
    function setPublicLinkKey(address _public_link_key) public {
        require(balanceOf(msg.sender) > 0,'no ARCs');
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
        // move ARCs and set public_link keys and weights/cuts based on signature information
        // returns the last address in the sig

        // sig structure:
        // 1 byte version 0 or 1
        // 20 bytes are the address of the contractor or the influencer who created sig.
        //  this is the "anchor" of the link
        //  It must have a public key aleady stored for it in public_link_key
        // Begining of a loop on steps in the link:
        // * 65 bytes are step-signature using the secret from previous step
        // * message of the step that is going to be hashed and used to compute the above step-signature.
        //   message length depend on version 41 (version 0) or 86 (version 1):
        //   * 1 byte cut (percentage) each influencer takes from the bounty. the cut is stored in influencer2cut or weight for voting
        //   * 20 bytes address of influencer (version 0) or 65 bytes of signature of cut using the influencer address to sign
        //   * 20 bytes public key of the last secret
        // In the last step the message can be optional. If it is missing the message used is the address of the sender
        address old_address;
        assembly
        {
            old_address := mload(add(sig, 21))
        }
        address old_key = publicLinkKey[old_address];

        address[] memory influencers;
        address[] memory keys;
        uint8[] memory cuts;
        (influencers, keys, cuts) = Call.recoverSig(sig, old_key);

        // check if we exactly reached the end of the signature. this can only happen if the signature
        // was generated with free_join_take and in this case the last part of the signature must have been
        // generated by the caller of this method
        require(influencers[influencers.length-1] == msg.sender || contractor == msg.sender,'only the contractor or the last in the link can call transferSig');

        uint i;
        address new_address;
        // move ARCs based on signature information
        for (i = 0; i < influencers.length; i++) {
            new_address = influencers[i];

            if (received_from[new_address] == 0) {
                transferFrom(old_address, new_address, 1);
            } else {
                require(received_from[new_address] == old_address,'only tree ARCs allowed');
            }
            old_address = new_address;
        }

        for (i = 0; i < keys.length; i++) {
            new_address = influencers[i];
            address key = keys[i];
            // TODO Updating the public key of influencers may not be a good idea because it will require the influencers to use
            // a deterministic private/public key in the link and this might require user interaction (MetaMask signature)
            // TODO a possible solution is change public_link_key to address=>address[]
            // update (only once) the public address used by each influencer
            // we will need this in case one of the influencers will want to start his own off-chain link
            if (publicLinkKey[new_address] == 0) {
                publicLinkKey[new_address] = key;
            } else {
                require(publicLinkKey[new_address] == key,'public key can not be modified');
            }
        }

        for (i = 0; i < cuts.length; i++) {
            new_address = influencers[i];
            uint256 weight = uint256(cuts[i]);

            // update (only once) the cut used by each influencer
            // we will need this in case one of the influencers will want to start his own off-chain link
            if (referrer2cut[new_address] == 0) {
                referrer2cut[new_address] = weight;
            } else {
                require(referrer2cut[new_address] == weight,'bounty cut can not be modified');
            }
        }
    }


    function joinAndShareARC(bytes signature, address receiver) public {
        distributeArcsBasedOnSignature(signature);
        transferFrom(msg.sender, receiver, 1);
    }

    function joinAndConvert(bytes signature) public payable {
        require(msg.value >= minContributionETH);
        require(msg.value <= maxContributionETH);
        distributeArcsBasedOnSignature(signature);
        createConversion(msg.value, msg.sender);
        balancesConvertersETH[msg.sender] += msg.value;
    }

    function convert() public payable  {
        require(msg.value >= minContributionETH);
        require(msg.value <= maxContributionETH);
        require(received_from[msg.sender] != address(0));
        createConversion(msg.value, msg.sender);
        balancesConvertersETH[msg.sender] += msg.value;
    }

    function() external payable {
        require(msg.value >= minContributionETH);
        require(msg.value <= maxContributionETH);
        require(balanceOf(msg.sender) > 0);
        createConversion(msg.value, msg.sender);
        balancesConvertersETH[msg.sender] += msg.value;
    }



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
            referrerTotalEarnings2KEY[influencers[i]] = referrerTotalEarnings2KEY[influencers[i]].add(b);
            emit Rewarded(influencers[i], b);
            total_bounty = total_bounty.add(b);
            _maxReferralRewardETHWei = _maxReferralRewardETHWei.sub(b);
        }

        contractorBalance = contractorBalance.add(_maxReferralRewardETHWei);
        contractorTotalProceeds = contractorTotalProceeds.add(_maxReferralRewardETHWei);
    }


    /// @notice Move some amount of ERC20 from our campaignInventoryUnitsBalance to someone
    /// @dev internal function
    /// @param _to address we're sending the amount of ERC20
    /// @param _amount is the amount of ERC20's we're going to transfer
    /// @return true if successful, otherwise reverts
    function moveFungibleAsset(address _to, uint256 _amount) internal onlyTwoKeyConversionHandler returns (bool) {
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


    /// @notice Function which will transfer fungible assets from contract to someone
    /// @param _to is the address we're sending the fungible assets
    /// @param _amount is the amount of ERC20 we're going to transfer
    /// @return true if trasaction completes otherwise transaction will revert
    function transferFungibleAsset(address _to, uint256 _amount) public returns (bool) {
        ///TODO: Who can call this check?
        return moveFungibleAsset(_to, _amount);
    }


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
        uint balance = Call.params1(assetContractERC20, "balanceOf(address)", uint(this));
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

    /// @notice Getter for the address status if it's joined
    /// @return true / false
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

    function sealAndApprove() public onlyContractor {
        require(block.timestamp > campaignStartTime && block.timestamp < campaignEndTime);
        require(withdrawApproved = false);
        withdrawApproved = true;
    }

    function cancel() public onlyContractor {
        conversionHandler.cancelAndRejectContract();
        withdrawApproved = false;
        canceled = true;
    }

    function isWithdrawApproved() public view returns (bool) {
        return withdrawApproved;
    }

//    function converterWithdrawEth() public {
//        require(canceled == true);
//        //transfer back funds to converter
//        msg.sender.transfer(balancesConvertersETH[msg.sender]);
//    }


    function contractorWithdrawEth() public onlyContractor {
        require(!isOngoing());
    }

}

//TODO: See how to link withdrawal of ETH awith