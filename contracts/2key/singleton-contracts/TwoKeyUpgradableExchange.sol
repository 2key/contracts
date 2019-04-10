pragma solidity ^0.4.24;

import "../../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../MaintainingPattern.sol";
import "../Upgradeable.sol";
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../libraries/SafeMath.sol";
import "../libraries/GetCode.sol";
import "../libraries/SafeERC20.sol";


contract TwoKeyUpgradableExchange is Upgradeable, MaintainingPattern {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address twoKeyExchangeContract;
    address twoKeyCampaignValidator;

    // The token being sold
    ERC20 public token;

    uint256 public rate; //2key to USD rate multiplied by 1000 (initially it's 95)

    uint256 public transactionCounter = 0;

    uint256 public weiRaised = 0;

    /**
     * @notice Event will be fired every time someone buys tokens
     */
    event TokenSell(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param receiver is who got the tokens
     * @param weiReceived is how weis paid for purchase
     * @param tokensBought is the amount of tokens purchased
     * @param rate is the global variable rate on the contract
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed receiver,
        uint256 weiReceived,
        uint256 tokensBought,
        uint256 rate
    );

    /**
     * @notice Constructor of the contract
     */
    function setInitialParams(
        uint256 _rate,
        address _twoKeyAdmin,
        ERC20 _token,
        address _twoKeyExchangeContract,
        address _twoKeyCampaignValidator,
        address[] _maintainers
    )
    external
    {
        //Validating that this can be called only once
        require(rate == 0);
        require(_rate != 0);

        rate = _rate;
        token = _token;
        twoKeyExchangeContract = _twoKeyExchangeContract;
        twoKeyCampaignValidator = _twoKeyCampaignValidator;
        twoKeyAdmin = _twoKeyAdmin;
        isMaintainer[msg.sender] = true; //for truffle deployment
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
    * @notice Modifier to restrict calling the method to anyone but authorized people
    */
    modifier onlyMaintainerOrTwoKeyAdmin {
        require(isMaintainer[msg.sender] == true || msg.sender == address(twoKeyAdmin));
        _;
    }

    /**
     * @notice Modifier which will validate if contract is allowed to buy tokens
     */
    modifier onlyValidatedContracts {
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }


    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    private
    {
        require(_beneficiary != address(0),'beneficiary address can not be 0' );
        require(_weiAmount != 0, 'wei ammount can not be 0');
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(
        uint256 _weiAmount
    )
    public
    view
    returns (uint256)
    {
        uint value;
        bool flag;
        (value,flag,,) = ITwoKeyExchangeRateContract(twoKeyExchangeContract).getFiatCurrencyDetails("USD");
        return (_weiAmount*value).mul(1000).div(rate).div(10**18);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(
        address _twoKeyAdmin
    )
    internal
    {
        _twoKeyAdmin.transfer(msg.value);
    }

    /**
     * @notice Function to buyTokens
     * @param _beneficiary to get
     * @return amount of tokens bought
     */
    function buyTokens(
        address _beneficiary
    )
    public
    payable
    onlyValidatedContracts
    returns (uint)
    {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        transactionCounter++;
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens,
            rate
        );
        _forwardFunds(twoKeyAdmin);
        return tokens;
    }

    function ()
    public
    payable
    onlyValidatedContracts
    {
        buyTokens(msg.sender);
    }
}
