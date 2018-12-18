pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./StandardTokenModified.sol";


contract TwoKeyEconomy is StandardTokenModified, Ownable {

    /*
        TwoKeyEconomy inheritance ERC20

                  ERC20Basic (interfaces)
                      |
                StandardToken (implementation and variables)
                      |
                TwoKeyEconomy (our token)

    */


    string public name = 'TwoKeyEconomy';
    string public symbol= '2KEY';
    uint8 public decimals= 18;

    address public twoKeyAdmin;

    modifier onlyTwoKeyAdmin {
        require(msg.sender == twoKeyAdmin);
        require(address(twoKeyAdmin) != 0);
        _;
    }

    constructor (address _twoKeyAdmin) Ownable() public {
        require(_twoKeyAdmin != address(0));
        twoKeyAdmin = _twoKeyAdmin;
        totalSupply_= 1000000000000000000000000000;
        balances[_twoKeyAdmin] = totalSupply_;
    }

    function changeAdmin(address _newAdmin) public onlyTwoKeyAdmin {
        require(_newAdmin != address(0));
        twoKeyAdmin = _newAdmin;
    }

    /// @notice TwoKeyAmin is available to freeze all transfers on ERC for some period of time
    /// @dev in TwoKeyAdmin only Congress can call this
    function freezeTransfers() public onlyTwoKeyAdmin {
        transfersFrozen = true;
    }

    /// @notice TwoKeyAmin is available to unfreeze all transfers on ERC for some period of time
    /// @dev in TwoKeyAdmin only Congress can call this
    function unfreezeTransfers() public onlyTwoKeyAdmin {
        transfersFrozen = false;
    }

}
