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

    function setInitialParams(address _twoKeyAdmin, address _erc20Address, address [] _maintainers) public {
        require(initialized = false);
        twoKeyAdmin = _twoKeyAdmin;
        erc20Address = _erc20Address;
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }
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
