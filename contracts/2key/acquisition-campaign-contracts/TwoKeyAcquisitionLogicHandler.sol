pragma solidity ^0.4.24;
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyConversionHandler.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignERC20.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyAcquisitionARC.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyConversionHandlerGetConverterState.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Call.sol";

/**
 * @author Nikola Madjarevic
 * Created at 1/15/19
 */
contract TwoKeyAcquisitionLogicHandler {

    using SafeMath for uint256;

    address public twoKeySingletoneRegistry;
    address public twoKeyAcquisitionCampaign;
    address public twoKeyConversionHandler;
    address twoKeyRegistry;
    address public ownerPlasma;

    address twoKeyEventSource;
    address assetContractERC20;
    address contractor;
    address moderator;


    bool isFixedInvestmentAmount; // This means that minimal contribution is equal maximal contribution
    bool isAcceptingFiatOnly; // Means that only fiat conversions will be able to execute -> no referral rewards at all

    uint campaignStartTime; // Time when campaign start
    uint campaignEndTime; // Time when campaign ends
    uint minContributionETHorFiatCurrency; //Minimal contribution
    uint maxContributionETHorFiatCurrency; //Maximal contribution
    uint pricePerUnitInETHWeiOrUSD; // There's single price for the unit ERC20 (Should be in WEI)
    uint unit_decimals; // ERC20 selling data
    uint maxConverterBonusPercent; // Maximal bonus percent per converter

    string public publicMetaHash; // Ipfs hash of json campaign object
    string privateMetaHash; // Ipfs hash of json sensitive (contractor) information
    string public currency; // Currency campaign is currently in

    //Referral accounting stuff
    mapping(address => uint256) internal referrerPlasma2TotalEarnings2key; // Total earnings for referrers
    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
    mapping(address => mapping(uint256 => uint256)) internal referrerPlasma2EarningsPerConversion;


    modifier onlyContractor {
        require(msg.sender == contractor);
        _;
    }

    constructor(
        uint _minContribution,
        uint _maxContribution,
        uint _pricePerUnitInETHWeiOrUSD,
        uint _campaignStartTime,
        uint _campaignEndTime,
        uint _maxConverterBonusPercent,
        string _currency,
        address _assetContractERC20,
        address _moderator
    ) public {
        require(_minContribution > 0,"min contribution criteria not satisfied");
        require(_maxContribution >= _minContribution, "max contribution criteria not satisfied");
        require(_campaignEndTime > _campaignStartTime, "campaign start time can't be greater than end time");
        require(_maxConverterBonusPercent > 0, "max converter bonus percent should be 0");

        if(_minContribution == _maxContribution) {
            isFixedInvestmentAmount = true;
        }

        contractor = msg.sender;
        minContributionETHorFiatCurrency = _minContribution;
        maxContributionETHorFiatCurrency = _maxContribution;
        pricePerUnitInETHWeiOrUSD = _pricePerUnitInETHWeiOrUSD;
        campaignStartTime = _campaignStartTime;
        campaignEndTime = _campaignEndTime;
        maxConverterBonusPercent = _maxConverterBonusPercent;
        currency = _currency;
        moderator = _moderator;
        assetContractERC20 = _assetContractERC20;
        unit_decimals = IERC20(_assetContractERC20).decimals();
    }


    /**
     * @notice Requirement for the checking if the campaign is active or not
     */
    function requirementIsOnActive() public view returns (bool) {
        if(block.timestamp >= campaignStartTime && block.timestamp <= campaignEndTime) {
            return true;
        }
        return false;
    }



    function setTwoKeyAcquisitionCampaignContract(
        address _acquisitionCampaignAddress,
        address _twoKeySingletoneRegistry,
        address _twoKeyConversionHandler
    ) public {
        require(twoKeyAcquisitionCampaign == address(0)); // Means it can be set only once
        twoKeyAcquisitionCampaign = _acquisitionCampaignAddress;
        twoKeySingletoneRegistry = _twoKeySingletoneRegistry;
        twoKeyEventSource = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletoneRegistry)
            .getContractProxyAddress("TwoKeyEventSource");
        twoKeyRegistry = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletoneRegistry).getContractProxyAddress("TwoKeyRegistry");

        ownerPlasma = plasmaOf(contractor);
        twoKeyConversionHandler = _twoKeyConversionHandler;
    }


    /**
     * @notice Function to get investment rules
     * @return tuple containing if investment amount is fixed, and lower/upper bound of the same if not (if yes lower = upper)
     */
    function getInvestmentRules() public view returns (bool,uint,uint) {
        return (isFixedInvestmentAmount, minContributionETHorFiatCurrency, maxContributionETHorFiatCurrency);
    }


    /**
     * @notice internal function to validate the request is proper
     * @param msgValue is the value of the message sent
     * @dev validates if msg.Value is in interval of [minContribution, maxContribution]
     */
    function requirementForMsgValue(uint msgValue) public view returns (bool) {
        //TODO: Add timestamp validation -> conversions
        if(keccak256(currency) == keccak256('ETH')) {
            require(msgValue >= minContributionETHorFiatCurrency);
            require(msgValue <= maxContributionETHorFiatCurrency);
        } else {
            address ethUSDExchangeContract = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletoneRegistry).getContractProxyAddress("TwoKeyExchangeRateContract");
            uint val;
            bool flag;
            (val, flag,,) = ITwoKeyExchangeRateContract(ethUSDExchangeContract).getFiatCurrencyDetails(currency);
            if(flag) {
                require((msgValue * val).div(10**18) >= minContributionETHorFiatCurrency); //converting ether to fiat
                require((msgValue * val).div(10**18) <= maxContributionETHorFiatCurrency); //converting ether to fiat
            } else {
                require(msgValue >= (val * minContributionETHorFiatCurrency).div(10**18)); //converting fiat to ether
                require(msgValue <= (val * maxContributionETHorFiatCurrency).div(10**18)); //converting fiat to ether
            }
        }
        return true;
    }

    /**
     * @notice Function which will calculate the base amount, bonus amount
     * @param conversionAmountETHWeiOrFiat is amount of eth in conversion
     * @return tuple containing (base,bonus)
     */
    function getEstimatedTokenAmount(uint conversionAmountETHWeiOrFiat, bool isFiatConversion) public view returns (uint, uint) {
        uint value = pricePerUnitInETHWeiOrUSD;
        uint baseTokensForConverterUnits;
        uint bonusTokensForConverterUnits;
        if(isFiatConversion == true) {
            baseTokensForConverterUnits = conversionAmountETHWeiOrFiat.div(value);
            bonusTokensForConverterUnits = baseTokensForConverterUnits.mul(maxConverterBonusPercent).div(100);
        } else {
            if(keccak256(currency) != keccak256('ETH')) {
                address ethUSDExchangeContract = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletoneRegistry).getContractProxyAddress("TwoKeyExchangeRateContract");
                uint rate;
                bool flag;
                (rate,flag,,) = ITwoKeyExchangeRateContract(ethUSDExchangeContract).getFiatCurrencyDetails(currency);
                if(flag) {
                    conversionAmountETHWeiOrFiat = (conversionAmountETHWeiOrFiat.mul(rate)).div(10 ** 18); //converting eth to $wei
                } else {
                    value = (value.mul(rate)).div(10 ** 18); //converting dollar wei to eth
                }
            }
        }

        baseTokensForConverterUnits = conversionAmountETHWeiOrFiat.mul(10 ** unit_decimals).div(value);
        bonusTokensForConverterUnits = baseTokensForConverterUnits.mul(maxConverterBonusPercent).div(100);
        return (baseTokensForConverterUnits, bonusTokensForConverterUnits);
    }

    /**
     * @notice Function to update MinContributionETH
     * @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
     * @param value is the new value we are going to set for minContributionETH
     */
    function updateMinContributionETHOrUSD(uint value) public onlyContractor {
        minContributionETHorFiatCurrency = value;
        //        twoKeyEventSource.updatedData(block.timestamp, value, "Updated maxContribution");
    }

    /**
     * @notice Function to update maxContributionETH
     * @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
     * @param value is the new maxContribution value
     */
    function updateMaxContributionETHorUSD(uint value) external onlyContractor {
        maxContributionETHorFiatCurrency = value;
        //        twoKeyEventSource.updatedData(block.timestamp, value, "Updated maxContribution");
    }

    /**
     * @notice Function to update /set publicMetaHash
     * @dev only Contractor can call this function, otherwise it will revert - emits Event when set/updated
     * @param value is the value for the publicMetaHash
     */
    function updateOrSetIpfsHashPublicMeta(string value) public onlyContractor {
        publicMetaHash = value;
        //        twoKeyEventSource.updatedPublicMetaHash(block.timestamp, value);
    }


    /**
     * @notice Setter for privateMetaHash
     * @dev only Contractor can call this method, otherwise function will revert
     * @param _privateMetaHash is string representation of private metadata hash
     */
    function setPrivateMetaHash(string _privateMetaHash) public onlyContractor {
        privateMetaHash = _privateMetaHash;
    }

    /**
     * @notice Getter for privateMetaHash
     * @dev only Contractor can call this method, otherwise function will revert
     * @return string representation of private metadata hash
     */
    function getPrivateMetaHash() public view onlyContractor returns (string) {
        return privateMetaHash;
    }

    /**
     * @notice Get all constants from the contract
     * @return all constants from the contract
     */
    function getConstantInfo() public view returns (uint,uint,uint,uint,uint,uint,uint) {
        return (
        campaignStartTime,
        campaignEndTime,
        minContributionETHorFiatCurrency,
        maxContributionETHorFiatCurrency,
        unit_decimals,
        pricePerUnitInETHWeiOrUSD,
        maxConverterBonusPercent);
    }


    /**
    * @notice Function to check balance of the ERC20 inventory (view - no gas needed to call this function)
    * @dev we're using Utils contract and fetching the balance of this contract address
    * @return balance value as uint
    */
    function getInventoryBalance() public view returns (uint) {
        uint balance = IERC20(assetContractERC20).balanceOf(twoKeyAcquisitionCampaign);
        return balance;
    }


    /**
     * @notice Function to check if the msg.sender has already joined
     * @return true/false depending of joined status
     */
    function getAddressJoinedStatus(address _address) public view returns (bool) {
        address plasma = plasmaOf(_address);
        if (_address == address(0)) {
            return false;
        }
        if (plasma == ownerPlasma || _address == address(moderator) ||
        ITwoKeyAcquisitionARC(twoKeyAcquisitionCampaign).getReceivedFrom(plasma) != address(0)
        || ITwoKeyAcquisitionARC(twoKeyAcquisitionCampaign).balanceOf(plasma) > 0) {
            return true;
        }
        return false;
    }



    /**
     * @notice Function to fetch stats for the address
     */
    function getAddressStatistic(address _address, bool plasma, bool flag, address referrer) internal view returns (bytes) {
        bytes32 state; // NOT-EXISTING AS CONVERTER DEFAULT STATE

        address eth_address = ethereumOf(_address);
        address plasma_address = plasmaOf(_address);

        if(_address == contractor) {
            abi.encodePacked(0, 0, 0, false, false);
        } else {
            bool isConverter;
            bool isReferrer;
            uint unitsConverterBought;
            uint referrerTotalBalance;
            uint amountConverterSpent;
            (amountConverterSpent, referrerTotalBalance, unitsConverterBought) = ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaign).getStatistics(eth_address, plasma_address);
            if(unitsConverterBought> 0) {
                isConverter = true;
                state = ITwoKeyConversionHandlerGetConverterState(twoKeyConversionHandler).getStateForConverter(eth_address);
            }
            if(referrerTotalBalance > 0) {
                isReferrer = true;
            }

            if(flag == false) {
                //referrer is address in signature
                //plasma_address is plasma address of the address requested in method
                referrerTotalBalance  = getTotalReferrerEarnings(referrer, eth_address);
            }

            return abi.encodePacked(
                amountConverterSpent,
                referrerTotalBalance,
                unitsConverterBought,
                isConverter,
                isReferrer,
                state
            );
        }
    }

    function recover(bytes signature) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding referrer to plasma")),
            keccak256(abi.encodePacked("GET_REFERRER_REWARDS"))));
        address x = Call.recoverHash(hash, signature, 0);
        return x;
    }

    /**
     * @notice Function to get super statistics
     * @param _user is the user address we want stats for
     * @param plasma is if that address is plasma or not
     * @param signature in case we're calling this from referrer who doesn't have yet opened wallet
     */
    function getSuperStatistics(address _user, bool plasma, bytes signature) public view returns (bytes) {
        address eth_address = _user;

        if (plasma) {
            (eth_address) = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(_user);
        }

        bytes memory userData = ITwoKeyReg(twoKeyRegistry).getUserData(eth_address);

        bool isJoined = getAddressJoinedStatus(_user);
        bool flag;

        address _address;

        if(msg.sender == contractor || msg.sender == eth_address) {
            flag = true;
        } else {
            _address = recover(signature);
            if(_address == ownerPlasma) {
                flag = true;
            }
        }
        bytes memory stats = getAddressStatistic(_user, plasma, flag, _address);
        return abi.encodePacked(userData, isJoined, eth_address, stats);
    }

    /**
     * @notice Function to return referrers participated in the referral chain
     * @param customer is the one who converted (bought tokens)
     * @param acquisitionCampaignContract is the acquisition campaign address
     * @return array of referrer addresses
     */
    function getReferrers(address customer, address acquisitionCampaignContract) public view returns (address[]) {
        address influencer = plasmaOf(customer);
        uint n_influencers = 0;

        while (true) {
            influencer = plasmaOf(ITwoKeyAcquisitionARC(acquisitionCampaignContract).getReceivedFrom(influencer));
            if (influencer == plasmaOf(contractor)) {
                break;
            }
            n_influencers++;
        }

        address[] memory influencers = new address[](n_influencers);
        influencer = plasmaOf(customer);

        while (n_influencers > 0) {
            influencer = plasmaOf(ITwoKeyAcquisitionARC(acquisitionCampaignContract).getReceivedFrom(influencer));
            n_influencers--;
            influencers[n_influencers] = influencer;
        }

        return influencers;
    }

    /**
     * @notice Update refferal chain with rewards (update state variables)
     * @param _maxReferralRewardETHWei is the max referral reward set
     * @param _converter is the address of the converter
     * @dev This function can only be called by TwoKeyConversionHandler contract
     */
    function updateRefchainRewards(uint256 _maxReferralRewardETHWei, address _converter, uint _conversionId, uint totalBounty2keys) public {
        require(msg.sender == twoKeyAcquisitionCampaign);
        address[] memory influencers = getReferrers(_converter,twoKeyAcquisitionCampaign);
        uint numberOfInfluencers = influencers.length;

        for (uint i = 0; i < numberOfInfluencers; i++) {
            uint256 b;

            if (i == influencers.length - 1) {  // if its the last influencer then all the bounty goes to it.
                b = totalBounty2keys;
            }
            else {
                uint256 cut = ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaign).getReferrerCut(influencers[i]);
                if (cut > 0 && cut <= 101) {
                    b = totalBounty2keys.mul(cut.sub(1)).div(100);
                } else {// cut == 0 or 255 indicates equal particine of the bounty
                    b = totalBounty2keys.div(influencers.length - i);
                }
            }

            //Update referrer current balance stored on Acquisition contract
            ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaign).updateReferrerPlasmaBalance(influencers[i],b);

            //All mappings are now stated to plasma addresses
            //Update values for accounting purpose
            referrerPlasma2EarningsPerConversion[influencers[i]][_conversionId] = b;
            referrerPlasma2TotalEarnings2key[influencers[i]] = referrerPlasma2TotalEarnings2key[influencers[i]].add(b);
            referrerPlasmaAddressToCounterOfConversions[influencers[i]]++;

            //Decrease bounty for distributed
            totalBounty2keys = totalBounty2keys.sub(b);
        }
    }


    /**
     * @notice Helper function to get how much _referrer address earned for all conversions for eth_address
     * @param _referrer is the address we're checking the earnings
     * @param eth_address is the converter address we're getting all conversion ids for
     * @return sum of all earnings
     */
    function getTotalReferrerEarnings(address _referrer, address eth_address) internal view returns (uint) {
        uint[] memory conversionIds = ITwoKeyConversionHandler(twoKeyConversionHandler).getConverterConversionIds(eth_address);
        uint sum = 0;
        for(uint i=0; i<conversionIds.length; i++) {
            sum += referrerPlasma2EarningsPerConversion[_referrer][conversionIds[i]];
        }
        return sum;
    }


    /**
     * @notice Function to get balance and total earnings for all referrer addresses passed in arg
     * @param _referrerPlasmaList is the array of plasma addresses of referrer
     * @return two arrays. 1st contains current plasma balance and 2nd contains total plasma balances
     */
    function getReferrersBalancesAndTotalEarnings(address[] _referrerPlasmaList) public view returns (uint256[], uint256[]) {
        require(ITwoKeyReg(twoKeyRegistry).isMaintainer(msg.sender));

        uint numberOfAddresses = _referrerPlasmaList.length;
        uint256[] memory referrersPendingPlasmaBalance = new uint256[](numberOfAddresses);
        uint256[] memory referrersTotalEarningsPlasmaBalance = new uint256[](numberOfAddresses);

        for (uint i=0; i<numberOfAddresses; i++){
            referrersPendingPlasmaBalance[i] = ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaign).getReferrerPlasmaBalance(_referrerPlasmaList[i]);
            referrersTotalEarningsPlasmaBalance[i] = referrerPlasma2TotalEarnings2key[_referrerPlasmaList[i]];
        }

        return (referrersPendingPlasmaBalance, referrersTotalEarningsPlasmaBalance);
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
            require(msg.sender == _referrer || msg.sender == contractor || ITwoKeyReg(twoKeyRegistry).isMaintainer(msg.sender));
            _referrer = plasmaOf(_referrer);
        } else {
            bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding referrer to plasma")),
                keccak256(abi.encodePacked("GET_REFERRER_REWARDS"))));
            _referrer = Call.recoverHash(hash, signature, 0);
        }

        uint[] memory earnings = new uint[](conversionIds.length);

        for(uint i=0; i<conversionIds.length; i++) {
            earnings[i] = referrerPlasma2EarningsPerConversion[_referrer][conversionIds[i]];
        }

        uint referrerBalance = ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaign).getReferrerPlasmaBalance(_referrer);
        return (referrerBalance, referrerPlasma2TotalEarnings2key[_referrer], referrerPlasmaAddressToCounterOfConversions[_referrer], earnings);
    }


    function getReferrerPlasmaTotalEarnings(address _referrer) public view returns (uint) {
        require(msg.sender == twoKeyAcquisitionCampaign);
        return referrerPlasma2TotalEarnings2key[_referrer];
    }

    /**
     * @notice Function to determine plasma address of ethereum address
     * @param me is the address (ethereum) of the user
     * @return an address
     */
    function plasmaOf(address me) public view returns (address) {
        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(me);
        if (plasma != address(0)) {
            return plasma;
        }
        return me;
    }

    /**
     * @notice Function to determine ethereum address of plasma address
     * @param me is the plasma address of the user
     * @return ethereum address
     */
    function ethereumOf(address me) public view returns (address) {
        address ethereum = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(me);
        if (ethereum != address(0)) {
            return ethereum;
        }
        return me;
    }

}
