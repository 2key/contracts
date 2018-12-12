pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import "./GetCode.sol";

contract TwoKeyUpgradableExchange is Crowdsale {

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
        require(isContractEligibleToBuyTokens[msg.sender] == true);
        _;
    }

	constructor(uint256 _rate, address _twoKeyAdmin, ERC20 _token, address _twoKeyUpgradableExchange)
		Crowdsale(_rate, _twoKeyAdmin, _token, _twoKeyUpgradableExchange) public {
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


    function () public payable {
        buyTokens(msg.sender);
    }
}
