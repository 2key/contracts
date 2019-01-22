pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./TwoKeyCampaignARC.sol";
import "./TwoKeyEventSource.sol";
import "./Call.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IUpgradableExchange.sol";
import "../interfaces/ITwoKeyConversionHandler.sol";
import "../interfaces/ITwoKeyAcquisitionLogicHandler.sol";
/**
 * @author Nikola Madjarevic
 * @notice Campaign which will sell ERC20 tokens
 */
contract TwoKeyAcquisitionCampaignERC20 is TwoKeyCampaignARC {

    using Call for *;

    address public conversionHandler;
    address public upgradableExchange;
    address public twoKeyAcquisitionLogicHandler;


    mapping(address => uint256) internal referrerPlasma2cut; // Mapping representing how much are cuts in percent(0-100) for referrer address
    mapping(address => uint256) internal referrerPlasma2BalancesEthWEI; // balance of EthWei for each influencer that he can withdraw
    mapping(address => uint256) internal referrerPlasma2TotalEarningsEthWEI; // Total earnings for referrers
    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions;

    mapping(address => address) public public_link_key;

    uint moderatorBalanceETHWei; //Balance of the moderator which can be withdrawn
    uint moderatorTotalEarningsETHWei; //Total earnings of the moderator all time

    uint256 contractorBalance;
    uint256 contractorTotalProceeds;

    mapping(address => uint256) balancesConvertersETH; // Amount converter put to the contract in Ether
    mapping(address => uint256) internal unitsConverterBought; // Number of units (ERC20 tokens) bought

    address assetContractERC20; // Asset contract is address of ERC20 inventory

    uint256 expiryConversionInHours; // How long converter can be pending before it will be automatically rejected and funds will be returned to convertor (hours)
    uint256 moderatorFeePercentage; // Fee which moderator gets
    uint256 maxReferralRewardPercent; // maxReferralRewardPercent is actually bonus percentage in ETH
    uint public reservedAmountOfTokens = 0;

//    bool public withdrawApproved = false; // Until contractor set this to be true, no one can withdraw funds etc.
//    bool canceled = false; // This means if contractor cancel everything


    /**
     * @notice Modifier which will enable only twoKeyConversionHandlerContract to execute some functions
     */
    modifier onlyTwoKeyConversionHandler() {
        require(msg.sender == address(conversionHandler));
        _;
    }

    constructor(
        address _twoKeyAcquisitionLogicHandler,
        address _twoKeyEventSource,
        address _conversionHandler,
        address _moderator,
        address _assetContractERC20,
        uint [] values,
        address _twoKeyUpgradableExchangeContract
    ) TwoKeyCampaignARC (
        _twoKeyEventSource,
        values[3]
    )
    public {
        twoKeyAcquisitionLogicHandler = _twoKeyAcquisitionLogicHandler;
        conversionHandler = _conversionHandler;
        upgradableExchange = _twoKeyUpgradableExchangeContract;
        contractor = msg.sender;
        moderator = _moderator;
        assetContractERC20 = _assetContractERC20;
        expiryConversionInHours = values[0];
        moderatorFeePercentage = values[1];
        maxReferralRewardPercent = values[2];
        ITwoKeyConversionHandler(conversionHandler).setTwoKeyAcquisitionCampaignERC20(address(this), _moderator, contractor, _assetContractERC20, _twoKeyEventSource);
        twoKeyEventSource.created(address(this), contractor, moderator);
    }

    /**
     * @notice Function to join with signature and share 1 arc to the receiver
     * @param signature is the signature
     * @param receiver is the address we're sending ARCs to
     */
    function joinAndShareARC(bytes signature, address receiver) public {
        distributeArcsBasedOnSignature(signature);
        transferFrom(msg.sender, receiver, 1);
    }

    /**
     * @notice Function which will unpack signature and get referrers, keys, and weights from it
     * @param sig is signature
     */
    function distributeArcsBasedOnSignature(bytes sig) private returns (address[]) {
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
        /**
           old address -> plasma address
           old key -> publicLinkKey[plasma]
         */
        assembly
        {
            old_address := mload(add(sig, 21))
        }
        old_address = twoKeyEventSource.plasmaOf(old_address);
        address old_key = public_link_key[old_address];

        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        (influencers, keys, weights) = Call.recoverSig(sig, old_key, twoKeyEventSource.plasmaOf(msg.sender));

        // check if we exactly reached the end of the signature. this can only happen if the signature
        // was generated with free_join_take and in this case the last part of the signature must have been
        // generated by the caller of this method
        require(// influencers[influencers.length-1] == msg.sender ||
            influencers[influencers.length-1] == twoKeyEventSource.plasmaOf(msg.sender) ||
            contractor == msg.sender,'only the contractor or the last in the link can call transferSig');
        uint i;
        address new_address;
        // move ARCs based on signature information
        for (i = 0; i < influencers.length; i++) {
            new_address = twoKeyEventSource.plasmaOf(influencers[i]);

            if (received_from[new_address] == 0) {
                transferFromInternal(old_address, new_address, 1);
            } else {
                require(received_from[new_address] == old_address,'only tree ARCs allowed');
            }
            old_address = new_address;

            // TODO Updating the public key of influencers may not be a good idea because it will require the influencers to use
            // a deterministic private/public key in the link and this might require user interaction (MetaMask signature)
            // TODO a possible solution is change public_link_key to address=>address[]
            // update (only once) the public address used by each influencer
            // we will need this in case one of the influencers will want to start his own off-chain link
            if (i < keys.length) {
                setPublicLinkKeyOf(new_address, keys[i]);
            }

            // update (only once) the cut used by each influencer
            // we will need this in case one of the influencers will want to start his own off-chain link
            if (i < weights.length) {
                setCutOf(new_address, uint256(weights[i]));
            }
        }
        return influencers;
    }



    /**
     * @notice Private function which will be executed at the withdraw time to buy 2key tokens from upgradable exchange contract
     * @param amountOfMoney is the ether balance person has on the contract
     * @param receiver is the address of the person who withdraws money
     */
    function buyTokensFromUpgradableExchange(uint amountOfMoney, address receiver) internal {
        IUpgradableExchange(upgradableExchange).buyTokens.value(amountOfMoney)(receiver);
    }


    /**
     * @notice Private function to set public link key to plasma address
     * @param me is the ethereum address
     * @param new_public_key is the new key user want's to set as his public key
     */
    function setPublicLinkKeyOf(address me, address new_public_key) private {
        me = twoKeyEventSource.plasmaOf(me);
        require(balanceOf(me) > 0,'no ARCs');
        address old_address = public_link_key[me];
        if (old_address == address(0)) {
            public_link_key[me] = new_public_key;
        } else {
            require(old_address == new_public_key,'public key can not be modified');
        }
        public_link_key[me] = new_public_key;
    }


    /**
     * @notice Function to set public link key
     * @param new_public_key is the new public key
     */
    function setPublicLinkKey(address new_public_key) public {
        setPublicLinkKeyOf(msg.sender, new_public_key);
    }


    /**
     * @notice Method to add fungible asset to our contract
     * @dev When user calls this method, he just says the actual amount of ERC20 he'd like to transfer to us
     * @param _amount is the amount of ERC20 contract he'd like to give us
     * @return true if successful, otherwise transaction will revert
     */
    function addUnitsToInventory(uint256 _amount) public returns (bool) {
        require(IERC20(assetContractERC20).transferFrom(msg.sender, address(this), _amount),'Failed adding units to inventory');
        return true;
    }

    /**
     * @notice Function to set cut of
     * @param me is the address (ethereum)
     * @param cut is the cut value
     */
    function setCutOf(address me, uint256 cut) internal {
        // what is the percentage of the bounty s/he will receive when acting as an influencer
        // the value 255 is used to signal equal partition with other influencers
        // A sender can set the value only once in a contract
        address plasma = twoKeyEventSource.plasmaOf(me);
        require(referrerPlasma2cut[plasma] == 0 || referrerPlasma2cut[plasma] == cut, 'cut already set differently');
        referrerPlasma2cut[plasma] = cut;
    }

    /**
     * @notice Function to set cut
     * @param cut is the cut value
     * @dev Executes internal setCutOf method
     */
    function setCut(uint256 cut) public {
        setCutOf(msg.sender, cut);
    }


    function conversionOffline(address _converterAddress, uint _fiatAmount) public {
        /**
         * @notice Function where investor can state how much money he put to the contractorBalance
         * since we're accepting only fiat, we can do literal calculation of how many tokens he gets
         * then execute lockups
         * in this case there are no referral rewards

         */
    }

    /**
     * @notice Function where converter can join and convert
     * @dev payable function
     */
    function joinAndConvert(bytes signature, bool _isAnonymous) public payable {
        ITwoKeyAcquisitionLogicHandler(twoKeyAcquisitionLogicHandler).requirementForMsgValue(msg.value);
        distributeArcsBasedOnSignature(signature);
        createConversion(msg.value, msg.sender);
        ITwoKeyConversionHandler(conversionHandler).setAnonymous(msg.sender, _isAnonymous);
        balancesConvertersETH[msg.sender] += msg.value;
        twoKeyEventSource.converted(address(this),msg.sender,msg.value);
    }


    /**
     * @notice Function where converter can convert
     * @dev payable function
     */
    function convert(bool _isAnonymous) public payable {
        ITwoKeyAcquisitionLogicHandler(twoKeyAcquisitionLogicHandler).requirementForMsgValue(msg.value);
        address _converterPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        require(received_from[_converterPlasma] != address(0));
        createConversion(msg.value, msg.sender);
        ITwoKeyConversionHandler(conversionHandler).setAnonymous(msg.sender, _isAnonymous);
        balancesConvertersETH[msg.sender] += msg.value;
        twoKeyEventSource.converted(address(this),msg.sender,msg.value);
    }

    /*
     * @notice Function which is executed to create conversion
     * @param conversionAmountETHWei is the amount of the ether sent to the contract
     * @param converterAddress is the sender of eth to the contract
     * @dev can be called only internally
     */
    function createConversion(uint conversionAmountETHWei, address converterAddress) internal {
        uint baseTokensForConverterUnits;
        uint bonusTokensForConverterUnits;

        (baseTokensForConverterUnits, bonusTokensForConverterUnits)
        = ITwoKeyAcquisitionLogicHandler(twoKeyAcquisitionLogicHandler).getEstimatedTokenAmount(conversionAmountETHWei);

        uint totalTokensForConverterUnits = baseTokensForConverterUnits + bonusTokensForConverterUnits;

        uint256 _total_units = getInventoryBalance();
        require(_total_units - reservedAmountOfTokens >= totalTokensForConverterUnits, 'Inventory balance does not have enough funds');

        unitsConverterBought[converterAddress] = unitsConverterBought[converterAddress].add(totalTokensForConverterUnits);

        uint256 maxReferralRewardETHWei = conversionAmountETHWei.mul(maxReferralRewardPercent).div(100);
        uint256 moderatorFeeETHWei = calculateModeratorFee(conversionAmountETHWei);

        uint256 contractorProceedsETHWei = conversionAmountETHWei - maxReferralRewardETHWei - moderatorFeeETHWei;

        reservedAmountOfTokens = reservedAmountOfTokens + totalTokensForConverterUnits;

        ITwoKeyConversionHandler(conversionHandler).supportForCreateConversion(contractor, contractorProceedsETHWei, converterAddress,
            conversionAmountETHWei, maxReferralRewardETHWei, moderatorFeeETHWei,
            baseTokensForConverterUnits,bonusTokensForConverterUnits,
            expiryConversionInHours);
    }

    /**
     * @notice Update refferal chain with rewards (update state variables)
     * @param _maxReferralRewardETHWei is the max referral reward set
     * @param _converter is the address of the converter
     * @dev This function can only be called by TwoKeyConversionHandler contract
     */
    function updateRefchainRewards(uint256 _maxReferralRewardETHWei, address _converter) public onlyTwoKeyConversionHandler {
        require(_maxReferralRewardETHWei > 0, 'Max referral reward in ETH must be > 0');
        address converter = _converter;
        address[] memory influencers = getReferrers(converter);

        uint256 total_bounty = 0;
        for (uint i = 0; i < influencers.length; i++) {
            uint256 b;
            if (i == influencers.length - 1) {  // if its the last influencer then all the bounty goes to it.
                b = _maxReferralRewardETHWei;
            }
            else {
                uint256 cut = referrerPlasma2cut[influencers[i]];
                if (cut > 0 && cut <= 101) {
                    b = _maxReferralRewardETHWei.mul(cut.sub(1)).div(100);
                } else {// cut == 0 or 255 indicates equal particine of the bounty
                    b = _maxReferralRewardETHWei.div(influencers.length - i);
                }
            }
            //All mappings are now stated to plasma addresses
            referrerPlasma2BalancesEthWEI[influencers[i]] = referrerPlasma2BalancesEthWEI[influencers[i]].add(b);
            referrerPlasma2TotalEarningsEthWEI[influencers[i]] = referrerPlasma2TotalEarningsEthWEI[influencers[i]].add(b);
            referrerPlasmaAddressToCounterOfConversions[influencers[i]]++;
//            emit Rewarded(influencers[i], b);
            total_bounty = total_bounty.add(b);
            _maxReferralRewardETHWei = _maxReferralRewardETHWei.sub(b);
        }
    }


    /**
     * @notice Function to send ether back to converter if his conversion is cancelled
     * @param _cancelledConverter is the address of cancelled converter
     * @param _conversionAmount is the amount he sent to the contract
     * @dev This function can be called only by conversion handler
     */
    function sendBackEthWhenConversionCancelled(address _cancelledConverter, uint _conversionAmount) public onlyTwoKeyConversionHandler {
        _cancelledConverter.transfer(_conversionAmount);
    }

    /**
     * @notice Move some amount of ERC20 from our campaign to someone
     * @dev internal function
     * @param _to address we're sending the amount of ERC20
     * @param _amount is the amount of ERC20's we're going to transfer
     * @return true if successful, otherwise reverts
     */
    function moveFungibleAsset(address _to, uint256 _amount) public onlyTwoKeyConversionHandler returns (bool) {
        require(getInventoryBalance() >= _amount, 'Campaign inventory should be greater than amount');
        require(IERC20(assetContractERC20).transfer(_to,_amount),'Transfer of ERC20 failed');
        return true;
    }

    /**
     * @notice Function to update moderator balance and total earnings by conversion handler at the moment of conversion execution
     * @param _value is the value added
     */
    function updateModeratorBalanceETHWei(uint _value) public onlyTwoKeyConversionHandler {
        moderatorBalanceETHWei = moderatorBalanceETHWei.add(_value);
        moderatorTotalEarningsETHWei = moderatorTotalEarningsETHWei.add(_value);
    }


    /**
     * @notice Function to update maxReferralRewardPercent
     * @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
     * @param value is the new referral percent value
     */
    function updateMaxReferralRewardPercent(uint value) external onlyContractor {
        maxReferralRewardPercent = value;
        twoKeyEventSource.updatedData(block.timestamp, value, "Updated maxReferralRewardPercent");
    }


    /**
     * @notice Option to update contractor proceeds
     * @dev can be called only from TwoKeyConversionHandler contract
     * @param value it the value we'd like to add to total contractor proceeds and contractor balance
     */
    function updateContractorProceeds(uint value) public onlyTwoKeyConversionHandler {
        contractorTotalProceeds = contractorTotalProceeds.add(value);
        contractorBalance = contractorBalance.add(value);
    }

    /**
     * @notice Function to update amount of the reserved tokens in case conversion is rejected
     * @param value is the amount to reduce from reserved state
     */
    function updateReservedAmountOfTokensIfConversionRejectedOrExecuted(uint value) public onlyTwoKeyConversionHandler {
        require(reservedAmountOfTokens - value >= 0);
        reservedAmountOfTokens = reservedAmountOfTokens - value;
    }

    /**
    * given the total payout, calculates the moderator fee
    * @param  _conversionAmountETHWei total payout for escrow
    * @return moderator fee
    */
    function calculateModeratorFee(uint256 _conversionAmountETHWei) internal view returns (uint256)  {
        if (moderatorFeePercentage > 0) {// send the fee to moderator
            uint256 fee = _conversionAmountETHWei.mul(moderatorFeePercentage).div(100);
            return fee;
        }
        return 0;
    }


    /**
     * @notice Function to get cut for an (ethereum) address
     * @param me is the ethereum address
     */
    function getReferrerCut(address me) public view returns (uint256) {
        return referrerPlasma2cut[twoKeyEventSource.plasmaOf(me)];
    }

    /**
     * @notice Function to check how much eth has been sent to contract from address
     * @param _from is the address we'd like to check balance
     * @return amount of ether sent to contract from the specified address
     */
    function getAmountAddressSent(address _from) public view returns (uint) {
        return balancesConvertersETH[_from];
    }

    /**
     * @notice Function to return the constants from the contract
     */
    function getConstantInfo() public view returns (uint,uint) {
        return (conversionQuota, maxReferralRewardPercent);
    }

    /**
     * @notice Function which acts like getter for all cuts in array
     * @param last_influencer is the last influencer
     * @return array of integers containing cuts respectively
     */
    function getReferrerCuts(address last_influencer) public view returns (uint256[]) {
        address[] memory influencers = getReferrers(last_influencer);
        uint256[] memory cuts = new uint256[](influencers.length + 1);
        for (uint i = 0; i < influencers.length; i++) {
            address influencer = influencers[i];
            cuts[i] = getReferrerCut(influencer);
        }
        cuts[influencers.length] = getReferrerCut(last_influencer);
        return cuts;
    }


    /**
     * @notice Function to check balance of the ERC20 inventory (view - no gas needed to call this function)
     * @dev we're using Utils contract and fetching the balance of this contract address
     * @return balance value as uint
     */
    function getInventoryBalance() public view returns (uint) {
        uint balance = IERC20(assetContractERC20).balanceOf(address(this));
        return balance;
    }

    /**
     * @notice Function to fetch moderator balance in ETH and his total earnings
     * @dev only contractor or moderator are eligible to call this function
     * @return value of his balance in ETH
     */
    function getModeratorBalanceAndTotalEarnings() external onlyContractorOrModerator view returns (uint,uint) {
        return (moderatorBalanceETHWei,moderatorTotalEarningsETHWei);
    }

    /**
     * @notice Function to check if the msg.sender has already joined
     * @return true/false depending of joined status
     */
    function getAddressJoinedStatus() public view returns (bool) {
        address plasma = twoKeyEventSource.plasmaOf(msg.sender);
        if(plasma == address(contractor) || msg.sender == address(moderator) || received_from[plasma] != address(0)
            || balanceOf(plasma) > 0) {
            return true;
        }
        return false;
    }

    /**
     * @notice Function to check available amount of the tokens on the contract
     */
    function getAvailableAndNonReservedTokensAmount() external view returns (uint) {
        uint inventoryBalance = getInventoryBalance();
        return (inventoryBalance - reservedAmountOfTokens);
    }

    /**
     * @notice Function to fetch contractor balance in ETH
     * @dev only contractor can call this function, otherwise it will revert
     * @return value of contractor balance in ETH WEI
     */
    function getContractorBalance() external onlyContractor view returns (uint) {
        return contractorBalance;
    }

    /**
     * @notice Function to fetch for the referrer his balance, his total earnings, and how many conversions he participated in
     * @dev only referrer by himself, moderator, or contractor can call this
     * @param _referrer is the address of referrer we're checking for
     * @return tuple containing this 3 information
     */
    function getReferrerBalanceAndTotalEarningsAndNumberOfConversions(address _referrer) public view returns (uint,uint,uint) {
        require(msg.sender == _referrer || msg.sender == contractor || msg.sender == moderator);
        _referrer = twoKeyEventSource.plasmaOf(_referrer);
        return (referrerPlasma2BalancesEthWEI[_referrer], referrerPlasma2TotalEarningsEthWEI[_referrer], referrerPlasmaAddressToCounterOfConversions[_referrer]);
    }

    function publicLinkKeyOf(address me) public view returns (address) {
        return public_link_key[twoKeyEventSource.plasmaOf(me)];
    }

    //{ rewards: number,  tokens_bought: number, isConverter: bool, isReferrer: bool, isContractor: bool, isModerator:bool } right??
    function getAddressStatistic(address _address) public view returns (uint,uint,bool,bool,bool) {
        if(_address == contractor) {
            return (0, 0, false, false, true);
        } else {
            bool isConverter;
            bool isReferrer;
            if(unitsConverterBought[_address] > 0) {
                isConverter = true;
            }
            if(referrerPlasma2BalancesEthWEI[twoKeyEventSource.plasmaOf(_address)] > 0) {
                isReferrer = true;
            }
            return (referrerPlasma2BalancesEthWEI[twoKeyEventSource.plasmaOf(_address)], unitsConverterBought[_address], isConverter, isReferrer, false);
        }
    }


    /**
     * @notice Function where contractor can withdraw his funds
     * @dev onlyContractor can call this method
     * @return true if successful otherwise will 'revert'
     */
    function withdrawContractor() external onlyContractor {
        uint balance = contractorBalance;
        contractorBalance = 0;
        /**
         * In general transfer by itself prevents against reentrancy attack since it will throw if more than 2300 gas
         * but however it's not bad to practice this pattern of firstly reducing balance and then doing transfer
         */
        contractor.transfer(balance);
    }


    /**
     * @notice Function where moderator or referrer can withdraw their available funds
     */
    function withdrawModeratorOrReferrer() external {
        //Creating additional variable to prevent reentrancy attack
        uint balance;
        if(msg.sender == moderator) {
            balance = moderatorBalanceETHWei;
            moderatorBalanceETHWei = 0;
            buyTokensFromUpgradableExchange(balance,msg.sender);
        } else {
            address _referrer = twoKeyEventSource.plasmaOf(msg.sender);
            if(referrerPlasma2BalancesEthWEI[_referrer] != 0) {
                balance = referrerPlasma2BalancesEthWEI[_referrer];
                referrerPlasma2BalancesEthWEI[_referrer] = 0;
                buyTokensFromUpgradableExchange(balance, msg.sender);
            } else {
                revert();
            }
        }
    }

}
