pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import "./GetCode.sol";
import "./MaintainingPattern.sol";

contract TwoKeyUpgradableExchange is MaintainingPattern {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;


    address public twoKeyExchangeContract;


    // The token being sold
    ERC20 public token;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 public rate;

    uint256 public transactionCounter = 0;

    // Amount of wei raised
    uint256 public weiRaised = 0;

    /**
     * @notice Mapping which will map contract bytecode to boolean if that bytecode is eligible to buy tokens
     */
    mapping(bytes => bool) isContractEligibleToBuyTokens;

    /**
     * @notice Event will be fired every time someone buys tokens
     */
    event TokenSell(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );


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
    private
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
    private
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount)
    private view returns (uint256)
    {
        uint value;
        bool flag;
        (value,flag,,) = ITwoKeyExchangeContract(twoKeyExchangeContract).getFiatCurrencyDetails("USD");
        return (_weiAmount*value).div(10**18).div(rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(address _twoKeyAdmin) private {
        _twoKeyAdmin.transfer(msg.value);
    }


    /**
     * @notice Modifier which will validate if contract is eligible to buy tokens
     */
    modifier onlyEligibleContracts {
        bytes memory code = GetCode.at(msg.sender);
        require(isContractEligibleToBuyTokens[code] == true);
        _;
    }

    /**
     * @notice Constructor of the contract
     */
	constructor(uint256 _rate, address _twoKeyAdmin, ERC20 _token, address _twoKeyExchangeContract, address[] _maintainers)
		MaintainingPattern(_maintainers, _twoKeyAdmin) public {
        require(_rate > 0);
        require(_token != address(0));

        rate = _rate;
        token = _token;
        twoKeyExchangeContract = _twoKeyExchangeContract;
	}

    /**
     * @notice Function to add contract code to be eligible to buyTokens
     * @param _contractAddress is the address of the deployed contract
     * @dev only maintainer / admin can call this function
     */
    function addContractToBeEligibleToBuyTokens(address _contractAddress) public {
        require(_contractAddress != address(0));
        bytes memory _contractCode = GetCode.at(_contractAddress);
        isContractEligibleToBuyTokens[_contractCode] = true;
    }

    /**
     * Function to buyTokens
     */
    function buyTokens(address _beneficiary) public payable onlyEligibleContracts {
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
            tokens
        );
        _forwardFunds(twoKeyAdmin);
    }

    function () public payable onlyEligibleContracts {
        buyTokens(msg.sender);
    }
}
