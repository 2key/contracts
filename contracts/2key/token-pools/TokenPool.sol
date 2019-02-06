pragma solidity ^0.4.24;

import "../Upgradeable.sol";
import "../MaintainingPattern.sol";
import "../../interfaces/IERC20.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TokenPool is Upgradeable, MaintainingPattern {

    bool initialized = false;
    address public erc20Address;

    /**
     * @notice Function to retrieve the balance of tokens on the contract
     */
    function getContractBalance() public view returns (uint) {
        return IERC20(erc20Address).balanceOf(address(this));
    }

    /**
     * @notice Function to transfer tokens
     */
    function transferTokens(address receiver, uint amount) internal {
        IERC20(erc20Address).transfer(receiver,amount);
    }

}
