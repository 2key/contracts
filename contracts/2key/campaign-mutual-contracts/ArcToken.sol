pragma solidity ^0.4.24;

/**
 * @author Nikola Madjarevic
 */
contract ArcToken {

    uint256 internal totalSupply_;

    mapping(address => uint256) internal balances;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}
