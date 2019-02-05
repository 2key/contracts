pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import "./GetCode.sol";
import "./MaintainingPattern.sol";
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "./Upgradeable.sol";

contract TwoKeyUpgradableExchange is Upgradeable, MaintainingPattern {

    using GetCode for *;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;


    address twoKeyExchangeContract;

    // The token being sold
    ERC20 public token;

    uint256 public rate;

    uint256 public transactionCounter = 0;

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
     * @notice Constructor of the contract
     */
    function setInitialParams(uint256 _rate, address _twoKeyAdmin, ERC20 _token, address _twoKeyExchangeContract, address[] _maintainers) public {
        //Validating that this can be called only once
        require(rate == 0);
        require(_rate != 0);

        rate = _rate;
        token = _token;
        twoKeyExchangeContract = _twoKeyExchangeContract;

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
        (value,flag,,) = ITwoKeyExchangeRateContract(twoKeyExchangeContract).getFiatCurrencyDetails("USD");
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
     * @notice Function to buyTokens
     * @param _beneficiary to get
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

    /**
     * @notice Function to validate if an deployed contract is eligible to buy tokens
     * @param _deployedContractAddress is the address of the deployed contract
     */
    function isContractAddressEligibleToBuyTokens(address _deployedContractAddress) public view returns (bool) {
        bytes memory code = GetCode.at(_deployedContractAddress);
        return isContractEligibleToBuyTokens[code];
    }
}
