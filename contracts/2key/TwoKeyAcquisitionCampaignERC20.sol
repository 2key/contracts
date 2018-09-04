pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/math/SafeMath.sol';
import "./TwoKeyTypes.sol";
import "./TwoKeyCampaignARC.sol";
import "./TwoKeyEventSource.sol";
import "./TwoKeyWhitelisted.sol";
import './TwoKeyEconomy.sol';
import "../interfaces/IERC20.sol";

/// @author Nikola Madjarevic
/// Contract which will represent campaign for the fungible assets
contract TwoKeyAcquisitionCampaignERC20 is TwoKeyCampaignARC, TwoKeyTypes {


    /// @notice Event which will be emitted when
    event Expired(address indexed _contract);
    event ReceivedEther(address _sender, uint value);

    using SafeMath for uint256;

    /// Structure which will represent conversion
    struct Conversion {
        address from;
        uint256 payout;
        address converter;
        bool isFulfilled;
        bool isCancelled;
        string assetName;
        address assetContract;
        uint256 amount;
        CampaignType campaignType;
        uint256 openingTime;
        uint256 closingTime;
    }


    mapping (address => Conversion) public conversions;
    mapping (address => uint) balancesConvertersETH;

    uint campaignInventoryUnitsBalance; // balance will represent how many that tokens (erc20) we have on our Campaign
    address assetContract; //asset contract is address of that ERC20 inventory
    string assetName;
    // TwoKeyEventSource contract is instantiated in TwoKeyARC
    // address contractor is instantiated in TwoKeyArc


    TwoKeyEconomy twoKeyEconomy;
    TwoKeyWhitelisted whitelistInfluencer;
    TwoKeyWhitelisted whitelistConverter;


    uint price; /// There's single price for the unit ERC20
    uint256 rate; /// rate of conversion from TwoKey to ETH
    uint openingTime;
    uint closingTime;
    address moderator;
    uint256 expiryConversion; /// how long will hold asset in escrow
    uint256 escrowPercentage; /// percentage of payout to. be paid for moderator for escrow
    uint256 maxPi;


    constructor(address _twoKeyEventSource, address _twoKeyEconomy,
                address _whitelistInfluencer, address _whitelistConverter,
                address _contractor, address _moderator, uint _openingTime, uint _closingTime,
                    uint _expiryConversion, uint _escrowPercentage, uint _rate, uint _maxPi) TwoKeyCampaignARC(_twoKeyEventSource, _contractor)StandardToken()
            public {
                require(_twoKeyEconomy != address(0));
                require(_whitelistInfluencer != address(0));
                require(_whitelistConverter != address(0));
                require(_rate > 0);
                require(_maxPi > 0);


                twoKeyEconomy = TwoKeyEconomy(_twoKeyEconomy);
                whitelistInfluencer = TwoKeyWhitelisted(_whitelistInfluencer);
                whitelistConverter = TwoKeyWhitelisted(_whitelistConverter);

                moderator = _moderator;
                openingTime = _openingTime;
                closingTime = _closingTime;
                expiryConversion = _expiryConversion;
                escrowPercentage = _escrowPercentage;
                maxPi = _maxPi;

                // Emit event that TwoKeyCampaign is created
//                twoKeyEventSource.created(address(this), contractor);
    }

    /// @notice Function to add asset contract of specific ERC20
    /// @param _assetContract of that asset Contract
    function addAssetContractERC20(address _assetContract) public {
        assetContract = _assetContract;
    }

    /// @notice Modifier which is going to check if current time is between opening-closing campaign time
    modifier isOngoing() {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

    /// @notice Modifier which is going to check if campaign is closed (if time is greater then closing time)
    modifier isClosed() {
        require(now > closingTime);
        _;
    }

    /// @notice Modifier to check is the influencer eligible for participation in campaign
    modifier isWhiteListedInfluencer() {
        require(whitelistInfluencer.isWhitelisted(msg.sender));
        _;
    }

    /// @notice Modifier to check is the converter eligible for participation in conversion
    modifier isWhitelistedConverter() {
        require(whitelistConverter.isWhitelisted(msg.sender));
        _;
    }


    /// @notice Modifier to check if the Converter did the conversion
    modifier didConverterConvert() {
        Conversion memory c = conversions[msg.sender];
        require(!c.isFulfilled && !c.isCancelled);
        _;
    }


    /// @notice Method to add fungible asset to our contract
    /// @dev When user calls this method, he just says the actual amount of ERC20 he'd like to transfer to us
    /// @param _amount is the amount of ERC20 contract he'd like to give us
    /// @return true if successful, otherwise transaction will revert
    function addFungibleAsset(uint256 _amount) public returns (bool) {
        require(
            assetContract.call(
                bytes4(keccak256("transferFrom(address,address,uint256)")),
                msg.sender,
                address(this),
                _amount
            )
        );

        /// Add amount of assets to our contract balance tracking
//        balances[msg.sender] += _amount;
        campaignInventoryUnitsBalance += _amount;
        return true;
    }

    function checkInventoryBalance() public view returns (uint) {
        uint balance = IERC20(assetContract).balanceOf(address(this));
        return balance;
    }

    function checkAndUpdateInventoryBalance() public returns (uint) {
        uint balance = checkInventoryBalance();
        campaignInventoryUnitsBalance = balance;
        return balance;
    }
    /// @notice Move some amount of ERC20 from our campaignInventoryUnitsBalance to someone
    /// @dev internal function
    /// @param _to address we're sending the amount of ERC20
    /// @param _amount is the amount of ERC20's we're going to transfer
    /// @return true if successful, otherwise reverts
    function moveFungibleAsset(address _to, uint256 _amount) internal returns (bool) {
        require(campaignInventoryUnitsBalance >= _amount);
        require(
            assetContract.call(
                bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
                _to, _amount
            )
        );
        campaignInventoryUnitsBalance = campaignInventoryUnitsBalance - _amount;
        return true;
    }

    // transfer an amount of erc20 from our catalogue to someone
    // This should be called when conversion is executed
    // Refactor!
    function transferFungibleAsset(address _to, uint256 _amount) public returns (bool) {
        return moveFungibleAsset(_to, _amount);
    }
    // TODO: Udis code which sends rewards etc get it
    // TODO: Expiry of conversion event (Two-steps for conversion user puts in ether, and converter being approved by KYC)
    // TODO: When conversion happens, there's timeout where converter can be approved, otherwise everything's transfered to contractor

    /// I wanna pay for something with TwoKey tokens
    /// Amount should be the amount of twokey tokens
    /// tokenID -> assetName
    /// Acquisition campaign is campaign which is selling something which can be bought with 2key or ETH
    function fulfillFungibleTwoKeyToken(address _from, string _assetName, address _assetContract, uint256 _amount)  internal {
        require(_amount > 0);
        // require(price > 0);
//        uint256 payout = price.mul(_amount).mul(rate);

        /// Make sure that the payment has been sent
        require(twoKeyEconomy.transferFrom(msg.sender, this, _amount));

        /// compute how many units he can buy with amount of twokey
        /// TODO: Where's this defined, where's price defined
        uint units = 1;

        Conversion memory c = Conversion(_from, _amount, msg.sender, false, false, _assetName, _assetContract, units, CampaignType.CPA_FUNGIBLE, now, now + expiryConversion * 1 minutes);
        // move funds
        campaignInventoryUnitsBalance = campaignInventoryUnitsBalance - units;
//        twoKeyEventSource.escrow(address(this), msg.sender, _assetName, _assetContract, units, CampaignType.CPA_FUNGIBLE);
        conversions[msg.sender] = c;
    }

    function fulfillFungibleETH(
        address _from,
        uint256 _amountETH
        ) isOngoing internal {
        uint _amount = msg.value;
        // TODO: Idea is that payout is msg.value
        // Compute for the amount of ether how much tokens can be got by the amount
        require(_amount > 0);
//        require(price > 0);
        uint payout = 1;
//        uint256 payout = price.mul(_amount);
        require(msg.value == payout);
        //TODO: Someone put 100 eth and he's entitled to X base + Y bonus  = (X+Y) taken from Inventory
        //TODO: Take the msg.value, and regarding value I compute number of base and bonus tokens - sum of base and bonus is took out of the twoKeyCampaignInvent
        Conversion memory c = Conversion(_from, payout, msg.sender, false, false, assetName, assetContract, _amount, CampaignType.CPA_FUNGIBLE, now, now + expiryConversion * 1 days);


        // move funds
        // rename to remove from inventory
        campaignInventoryUnitsBalance = campaignInventoryUnitsBalance - _amount;
        //		removeFungibleAssets(_tokenID, _assetContract, _amount);

        //tokenID can be string specifying the name of token ("ETH", "BTC",etc)
        // value in escrow (msg.value), total amount of tokens
//        twoKeyEventSource.escrow(address(this), msg.sender, _assetName, _assetContract, _amount, CampaignType.CPA_FUNGIBLE);
        conversions[msg.sender] = c;
    }

    function buyFromWithTwoKey(address _from, string _assetName, address _assetContract, uint256 _amount) public payable {
        fulfillFungibleTwoKeyToken(_from, _assetName, _assetContract, _amount);
    }

    /**
     * given the total payout, calculates the moderator fee
     * @param  _payout total payout for escrow
     * @return moderator fee
     */
    function calculateModeratorFee(uint256 _payout) internal view returns (uint256)  {
        if (escrowPercentage > 0) { // send the fee to moderator
            uint256 fee = _payout.mul(escrowPercentage).div(100);
            return fee;
        }
        return 0;
    }

    function transferAssetTwoKeyToken(uint256 _tokenID, address _assetContract, uint256 _amount) isWhitelistedConverter didConverterConvert public {
        actuallyFulfilledTwoKeyToken();
        require(transferFungibleAsset(msg.sender, _amount));
    }

    function cancelledEscrow(address _converter, address _assetContract, uint256 _amount) internal {
        Conversion memory c = conversions[_converter];
        c.isCancelled = true;
        conversions[_converter] = c;
        addFungibleAsset(_amount);
        require(twoKeyEconomy.transfer(_converter, (c.payout).mul(rate)));
    }

    function cancelAssetTwoKey(address _converter, string _assetName, address _assetContract, uint256 _amount)  public returns (bool) {
        Conversion memory c = conversions[_converter];
        require(!c.isCancelled && !c.isFulfilled);
        cancelledEscrow(_converter, _assetContract, _amount);
        twoKeyEventSource.cancelled(address(this), _converter, _assetName, _assetContract, _amount, CampaignType.CPA_FUNGIBLE);

        return true;
    }

    //onlyRole(ROLE_CONTROLLER) - comment
    function expireEscrow(address _converter,address _assetContract, uint256 _amount) public returns (bool) {
        Conversion memory c = conversions[_converter];
        require(!c.isCancelled && !c.isFulfilled);
        require(now > c.closingTime);
        cancelledEscrow(_converter, _assetContract, _amount);
        emit Expired(address(this));
        return true;
    }

    function actuallyFulfilledTwoKeyToken() internal {
        Conversion memory c = conversions[msg.sender];
        c.isFulfilled = true;
        conversions[msg.sender] = c;
        uint256 fee = calculateModeratorFee(c.payout);

        require(twoKeyEconomy.transfer(moderator, fee.mul(rate)));

        uint256 payout = c.payout;
        uint256 maxReward = maxPi.mul(payout).div(100);

        // transfer payout - fee - rewards to seller
        require(twoKeyEconomy.transfer(contractor, (payout.sub(fee).sub(maxReward)).mul(rate)));

        transferRewardsTwoKeyToken(c.from, maxReward.mul(rate));
//        twoKeyEventSource.fulfilled(address(this), c.converter, c.tokenID, c.assetContract, c.indexOrAmount, c.campaignType);
    }

    // @notice Function where an influencer that wishes to cash an _amount of 2key from the campaign can do it
    function redeemTwoKeyToken(uint256 _amount) public {
        require(xbalancesTwoKey[msg.sender] >= _amount && _amount > 0);
        xbalancesTwoKey[msg.sender] = xbalancesTwoKey[msg.sender].sub(_amount);
        twoKeyEconomy.transferFrom(this, msg.sender, _amount);
    }

    /// handle incoming ether
    /// update mapping for address the amount sent
    /// emit event updated mapping
    /// function check amount for address

    /// @notice (Fallback)Payable function which will accept all transactions which are sending ether to contract
    /// @dev we require that msg.value is greater than 0
    /// @dev function will update the mapping balances where we're mapping how much ether has been sent to contract from specified address
    /// @dev will emit an event with address and value sent
    function () external payable {
        require(msg.value > 0);
        balancesConvertersETH[msg.sender] += msg.value;
//        fulfillFungibleETH(from, msg.value);
        emit ReceivedEther(msg.sender, msg.value);
    }

    /// @notice Function to check how much eth has been sent to contract from address
    /// @param _from is the address we'd like to check balance
    /// @return amount of ether sent to contract from the specified address
    function checkAmountAddressSent(address _from) public view returns (uint) {
        return balancesConvertersETH[_from];
    }

    /// @notice Function to check contract balance of specified ERC20 tokens
    /// @return balance
    function getContractBalance() public view returns(uint) {
        return campaignInventoryUnitsBalance;
    }

    /// @notice View function to fetch the address of asset contract
    /// @return address of that asset contract
    function getAssetContractAddress() public view returns(address) {
        return assetContract;
    }

}
