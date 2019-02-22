pragma solidity ^0.4.24;

import "../singleton-contracts/TwoKeyEventSource.sol";
import "../campaign-mutual-contracts/TwoKeyCampaign.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyConversionHandler.sol";
import "../interfaces/ITwoKeyAcquisitionLogicHandler.sol";

/**
 * @author Nikola Madjarevic
 * @notice Campaign which will sell ERC20 tokens
 */
contract TwoKeyAcquisitionCampaignERC20 is TwoKeyCampaign {

    address public conversionHandler;
    address public twoKeyAcquisitionLogicHandler;

    mapping(address => uint256) private amountConverterSpentFiatWei;
    mapping(address => uint256) private amountConverterSpentEthWEI; // Amount converter put to the contract in Ether
    mapping(address => uint256) private unitsConverterBought; // Number of units (ERC20 tokens) bought

    address assetContractERC20; // Asset contract is address of ERC20 inventory

    uint reservedAmountOfTokens = 0;

    constructor(
        address _twoKeySingletonesRegistry,
        address _twoKeyAcquisitionLogicHandler,
        address _conversionHandler,
        address _moderator,
        address _assetContractERC20,
        uint [] values
    ) public {
        contractor = msg.sender;
        moderator = _moderator;
        twoKeyEventSource = TwoKeyEventSource(ITwoKeySingletoneRegistryFetchAddress(_twoKeySingletonesRegistry).getContractProxyAddress("TwoKeyEventSource"));
        ownerPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        received_from[ownerPlasma] = ownerPlasma;
        balances[ownerPlasma] = totalSupply_;
        conversionQuota = values[1];

        twoKeySingletonesRegistry = _twoKeySingletonesRegistry;
        twoKeyAcquisitionLogicHandler = _twoKeyAcquisitionLogicHandler;
        conversionHandler = _conversionHandler;
        assetContractERC20 = _assetContractERC20;

        maxReferralRewardPercent = values[0];

        ITwoKeyConversionHandler(conversionHandler).setTwoKeyAcquisitionCampaignERC20(
            address(this),
            contractor,
            _assetContractERC20,
            address(twoKeyEventSource),
            ITwoKeySingletoneRegistryFetchAddress(_twoKeySingletonesRegistry)
                .getContractProxyAddress("TwoKeyBaseReputationRegistry")
        );

        ITwoKeyAcquisitionLogicHandler(twoKeyAcquisitionLogicHandler).setTwoKeyAcquisitionCampaignContract(
            address(this),
            _twoKeySingletonesRegistry
        );
    }

    /**
     * @notice Modifier which will enable only twoKeyConversionHandlerContract to execute some functions
     */
    modifier onlyTwoKeyConversionHandler() {
        require(msg.sender == address(conversionHandler));
        _;
    }

    function distributeArcsBasedOnSignature(bytes sig) private returns (address[]) {
        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        address old_address;
        (influencers, keys, weights, old_address) = super.getInfluencersKeysAndWeightsFromSignature(sig);
        uint i;
        address new_address;
        // move ARCs based on signature information
        // TODO: Handle failing of this function if the referral chain is too big
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
     */
    function createConversion(uint conversionAmountETHWeiOrFiat, address converterAddress, bool isFiatConversion) private {
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
            totalBounty = totalBounty.add(b);
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
     * @notice Function to check how much eth has been sent to contract from address
     * @param _from is the address we'd like to check balance
     * @return amount of ether sent to contract from the specified address
     */
    function getAmountAddressSent(address _from) public view returns (uint) {
        return amountConverterSpentEthWEI[_from];
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
     * @notice Function to get statistic for the address
     * @param ethereum is the ethereum address we want to get stats for
     * @param plasma is the corresponding plasma address for the passed ethereum address
     */
    function getStatistics(address ethereum, address plasma) public view returns (uint,uint,uint) {
        require(msg.sender == twoKeyAcquisitionLogicHandler);
        return (amountConverterSpentEthWEI[ethereum], referrerPlasma2BalancesEthWEI[plasma],unitsConverterBought[ethereum]);
    }

}
