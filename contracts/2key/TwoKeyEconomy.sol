pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./StandardTokenModified.sol";


contract TwoKeyEconomy is StandardTokenModified, Ownable {
    string public name = 'TwoKeyEconomy';
    string public symbol= '2KEY';
    uint8 public decimals= 18;

    address public twoKeyAdmin;
    address public twoKeySingletoneRegistry;

    modifier onlyTwoKeyAdmin {
        require(msg.sender == twoKeyAdmin);
        require(address(twoKeyAdmin) != 0);
        _;
    }

    constructor (address _twoKeyAdmin, address _twoKeySingletoneRegistry) Ownable() public {
        require(_twoKeyAdmin != address(0));
        twoKeyAdmin = _twoKeyAdmin;
        twoKeySingletoneRegistry = _twoKeySingletoneRegistry;
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
