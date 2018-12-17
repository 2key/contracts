pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import "./GetCode.sol";
import "./MaintainingPattern.sol";

contract TwoKeyUpgradableExchange is MaintainingPattern, Crowdsale {

	/**
	 * @notice Event will be fired every time someone buys tokens
     */
	event TokenSell(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @notice Mapping which will map contract bytecode to boolean if that bytecode is eligible to buy tokens
     */
    mapping(bytes => bool) isContractEligibleToBuyTokens;


    /**
     * @notice Modifier which will validate if contract is eligible to buy tokens
     */
    modifier onlyEligibleContracts {
        bytes memory code = GetCode.at(msg.sender);
        require(isContractEligibleToBuyTokens[code] == true);
        _;
    }

	constructor(uint256 _rate, address _twoKeyAdmin, ERC20 _token, address _twoKeyExchangeContract, address[] _maintainers)
		Crowdsale(_rate, _token, _twoKeyExchangeContract) MaintainingPattern(_maintainers, _twoKeyAdmin) public {
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
