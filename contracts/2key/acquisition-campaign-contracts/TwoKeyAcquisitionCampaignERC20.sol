pragma solidity ^0.4.24;

import "../singleton-contracts/TwoKeyEventSource.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignARC.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/IUpgradableExchange.sol";
import "../interfaces/ITwoKeyConversionHandler.sol";
import "../interfaces/ITwoKeyAcquisitionLogicHandler.sol";
import "../libraries/Call.sol";
import "../libraries/SafeMath.sol";

/**
 * @author Nikola Madjarevic
 * @notice Campaign which will sell ERC20 tokens
 */
contract TwoKeyAcquisitionCampaignERC20 is TwoKeyCampaignARC {

    using Call for *;
    using SafeMath for uint;

    address public conversionHandler;
    address public twoKeyAcquisitionLogicHandler;

    mapping(address => uint256) internal referrerPlasma2cut; // Mapping representing how much are cuts in percent(0-100) for referrer address
    mapping(address => uint256) internal referrerPlasma2BalancesEthWEI; // balance of EthWei for each influencer that he can withdraw
    mapping(address => uint256) internal referrerPlasma2TotalEarningsEthWEI; // Total earnings for referrers
    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
    mapping(address => mapping(uint => uint)) referrerPlasma2EarningsPerConversion;
    mapping(address => address) public public_link_key;

    uint moderatorBalanceETHWei; //Balance of the moderator which can be withdrawn
    uint moderatorTotalEarningsETHWei; //Total earnings of the moderator all time

    uint256 contractorBalance;
    uint256 contractorTotalProceeds;

    mapping(address => uint256) internal amountConverterSpentFiatWei;
    mapping(address => uint256) internal amountConverterSpentEthWEI; // Amount converter put to the contract in Ether
    mapping(address => uint256) internal unitsConverterBought; // Number of units (ERC20 tokens) bought

    address assetContractERC20; // Asset contract is address of ERC20 inventory

    uint256 maxReferralRewardPercent; // maxReferralRewardPercent is actually bonus percentage in ETH
    uint reservedAmountOfTokens = 0;

    /**
     * @notice Modifier which will enable only twoKeyConversionHandlerContract to execute some functions
     */
    modifier onlyTwoKeyConversionHandler() {
        require(msg.sender == address(conversionHandler));
        _;
    }


    constructor(
        address _twoKeySingletoneRegistry,
        address _twoKeyAcquisitionLogicHandler,
        address _conversionHandler,
        address _moderator,
        address _assetContractERC20,
        uint [] values
    ) TwoKeyCampaignARC (
        values[1],
        _twoKeySingletoneRegistry,
        _moderator
    )
    public {
        twoKeyAcquisitionLogicHandler = _twoKeyAcquisitionLogicHandler;
        conversionHandler = _conversionHandler;
        assetContractERC20 = _assetContractERC20;
        maxReferralRewardPercent = values[0];
        ITwoKeyConversionHandler(conversionHandler).setTwoKeyAcquisitionCampaignERC20(
            address(this),
            contractor,
            _assetContractERC20,
            address(twoKeyEventSource),
            ITwoKeySingletoneRegistryFetchAddress(_twoKeySingletoneRegistry)
                .getContractProxyAddress("TwoKeyBaseReputationRegistry")
        );
        ITwoKeyAcquisitionLogicHandler(twoKeyAcquisitionLogicHandler).setTwoKeyAcquisitionCampaignContract(
            address(this),
            _twoKeySingletoneRegistry
        );
    }

    /**
     * @notice Function to join with signature and share 1 arc to the receiver
     * @param signature is the signature
     * @param receiver is the address we're sending ARCs to
     */
    function joinAndShareARC(bytes signature, address receiver) public {
        distributeArcsBasedOnSignature(signature);
        transferFrom(twoKeyEventSource.plasmaOf(msg.sender), twoKeyEventSource.plasmaOf(receiver), 1);
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
        // move ARCs based on signature informationc
        uint numberOfInfluencers = influencers.length;
        for (i = 0; i < numberOfInfluencers; i++) {
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
        address upgradableExchange = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonesRegistry).getContractProxyAddress("TwoKeyUpgradableExchange");
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


    /**
     * @notice Function where converter can join and convert
     * @dev payable function
     */
    function joinAndConvert(bytes signature, bool _isAnonymous) public payable {
        ITwoKeyAcquisitionLogicHandler(twoKeyAcquisitionLogicHandler).requirementForMsgValue(msg.value);
        distributeArcsBasedOnSignature(signature);
        createConversion(msg.value, msg.sender, false);
        ITwoKeyConversionHandler(conversionHandler).setAnonymous(msg.sender, _isAnonymous);
        amountConverterSpentEthWEI[msg.sender] += msg.value;
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
        createConversion(msg.value, msg.sender, false);
        ITwoKeyConversionHandler(conversionHandler).setAnonymous(msg.sender, _isAnonymous);
        amountConverterSpentEthWEI[msg.sender] += msg.value;
        twoKeyEventSource.converted(address(this),msg.sender,msg.value);
    }

    /**
     * @notice Function to convert if the conversion is in fiat
     * @dev This can be executed only in case currency is fiat
     * @param conversionAmountFiatWei is the amount of conversion converted to wei units
     * @param _isAnonymous if converter chooses to be anonymous
     */
    function convertFiat(uint conversionAmountFiatWei, bool _isAnonymous) public {
        createConversion(conversionAmountFiatWei, msg.sender, true);
        ITwoKeyConversionHandler(conversionHandler).setAnonymous(msg.sender, _isAnonymous);
        amountConverterSpentFiatWei[msg.sender] = amountConverterSpentFiatWei[msg.sender].add(conversionAmountFiatWei);
    }

    /*
     * @notice Function which is executed to create conversion
     * @param conversionAmountETHWeiOrFiat is the amount of the ether sent to the contract
     * @param converterAddress is the sender of eth to the contract
     * @dev can be called only internally
     */
    function createConversion(uint conversionAmountETHWeiOrFiat, address converterAddress, bool isFiatConversion) internal {
        uint baseTokensForConverterUnits;
        uint bonusTokensForConverterUnits;

        (baseTokensForConverterUnits, bonusTokensForConverterUnits)
        = ITwoKeyAcquisitionLogicHandler(twoKeyAcquisitionLogicHandler).getEstimatedTokenAmount(conversionAmountETHWeiOrFiat, isFiatConversion);

        uint totalTokensForConverterUnits = baseTokensForConverterUnits + bonusTokensForConverterUnits;

        uint256 _total_units = getInventoryBalance();
        require(_total_units - reservedAmountOfTokens >= totalTokensForConverterUnits, 'Inventory balance does not have enough funds');

        unitsConverterBought[converterAddress] = unitsConverterBought[converterAddress].add(totalTokensForConverterUnits);
        uint256 maxReferralRewardETHWei = 0;
        if(isFiatConversion == false) {
            maxReferralRewardETHWei = conversionAmountETHWeiOrFiat.mul(maxReferralRewardPercent).div(100);
            reservedAmountOfTokens = reservedAmountOfTokens + totalTokensForConverterUnits;
        }

        ITwoKeyConversionHandler(conversionHandler).supportForCreateConversion(contractor, converterAddress,
            conversionAmountETHWeiOrFiat, maxReferralRewardETHWei,
            baseTokensForConverterUnits,bonusTokensForConverterUnits, isFiatConversion);
    }

    /**
     * @notice Update refferal chain with rewards (update state variables)
     * @param _maxReferralRewardETHWei is the max referral reward set
     * @param _converter is the address of the converter
     * @dev This function can only be called by TwoKeyConversionHandler contract
     */
    function updateRefchainRewards(uint256 _maxReferralRewardETHWei, address _converter, uint _conversionId) public onlyTwoKeyConversionHandler {
        require(_maxReferralRewardETHWei > 0, 'Max referral reward in ETH must be > 0');
        address[] memory influencers = ITwoKeyAcquisitionLogicHandler(twoKeyAcquisitionLogicHandler).getReferrers(_converter,address(this));
        uint numberOfInfluencers = influencers.length;
        uint256 total_bounty = 0;
        for (uint i = 0; i < numberOfInfluencers; i++) {
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
            referrerPlasma2EarningsPerConversion[influencers[i]][_conversionId] = b;
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
    function moveFungibleAsset(address _to, uint256 _amount) public onlyTwoKeyConversionHandler {
        require(IERC20(assetContractERC20).transfer(_to,_amount));
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
        return amountConverterSpentEthWEI[_from];
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
        address[] memory influencers = ITwoKeyAcquisitionLogicHandler(twoKeyAcquisitionLogicHandler).getReferrers(last_influencer,address(this));
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
    function getModeratorBalanceAndTotalEarnings() external view returns (uint,uint) {
        require(msg.sender == contractor);
        return (moderatorBalanceETHWei,moderatorTotalEarningsETHWei);
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
     * @param signature is the signature if calling functions from FE without ETH address
     * @param conversionIds are the ids of conversions this referrer participated in
     * @return tuple containing this 3 information
     */
    function getReferrerBalanceAndTotalEarningsAndNumberOfConversions(address _referrer, bytes signature, uint[] conversionIds) public view returns (uint,uint,uint,uint[]) {
        if(_referrer != address(0)) {
            require(msg.sender == _referrer || msg.sender == contractor || twoKeyEventSource.isAddressMaintainer(msg.sender));
            _referrer = twoKeyEventSource.plasmaOf(_referrer);
        } else {
            bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding referrer to plasma")),
                keccak256(abi.encodePacked("GET_REFERRER_REWARDS"))));
            _referrer = Call.recoverHash(hash, signature, 0);
        }
        uint length = conversionIds.length;
        uint[] memory earnings = new uint[](length);
        for(uint i=0; i<length; i++) {
            earnings[i] = referrerPlasma2EarningsPerConversion[_referrer][conversionIds[i]];
        }
        return (referrerPlasma2BalancesEthWEI[_referrer], referrerPlasma2TotalEarningsEthWEI[_referrer], referrerPlasmaAddressToCounterOfConversions[_referrer], earnings);
    }

    /**
     * @notice Function to get public link key of an address
     * @param me is the address we're checking public link key
     */
    function publicLinkKeyOf(address me) public view returns (address) {
        return public_link_key[twoKeyEventSource.plasmaOf(me)];
    }


    function getStatistics(address ethereum, address plasma) public view returns (uint,uint,uint) {
        require(msg.sender == twoKeyAcquisitionLogicHandler);
        return (amountConverterSpentEthWEI[ethereum], referrerPlasma2BalancesEthWEI[plasma],unitsConverterBought[ethereum]);
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
         * Also if the contract is contractor, then it can revert every transfer
         */
        contractor.transfer(balance);
    }


    /**
     * @notice Function where moderator or referrer can withdraw their available funds
     * @param _address is the address we're withdrawing funds to
     * @dev It can be called by the address specified in the param or by the one of two key maintainers
     */
    function withdrawModeratorOrReferrer(address _address) external {
        require(msg.sender == _address || twoKeyEventSource.isAddressMaintainer(msg.sender));
        uint balance;
        if(_address == moderator) {
            address twoKeyDeepFreezeTokenPool = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonesRegistry).getContractProxyAddress("TwoKeyDeepFreezeTokenPool");
            uint integratorFee = twoKeyEventSource.getTwoKeyDefaultIntegratorFeeFromAdmin();
            balance = moderatorBalanceETHWei.mul(100-integratorFee).div(100);
            uint networkFee = moderatorBalanceETHWei.mul(integratorFee).div(100);
            moderatorBalanceETHWei = 0;
            buyTokensFromUpgradableExchange(balance,_address);
            buyTokensFromUpgradableExchange(networkFee,twoKeyDeepFreezeTokenPool);
        } else {
            address _referrer = twoKeyEventSource.plasmaOf(_address);
            if(referrerPlasma2BalancesEthWEI[_referrer] != 0) {
                balance = referrerPlasma2BalancesEthWEI[_referrer];
                referrerPlasma2BalancesEthWEI[_referrer] = 0;
                buyTokensFromUpgradableExchange(balance, _address);
            } else {
                revert();
            }
        }

    }

}
