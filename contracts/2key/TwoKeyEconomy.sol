pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./RBACWithAdmin.sol";


contract TwoKeyEconomy is RBACWithAdmin, StandardToken, Ownable {

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
    }

    constructor (address _twoKeyAdmin) RBACWithAdmin(_twoKeyAdmin) Ownable() public {
        require(_twoKeyAdmin != address(0));
        twoKeyAdmin = _twoKeyAdmin;
        totalSupply_= 1000000000000000000000000;
        balances[_twoKeyAdmin] = totalSupply_;
    }

    function freezeTransfers() public onlyTwoKeyAdmin{
        frozen = true;
    }

    function unfreezeTransfers() public onlyTwoKeyAdmin {
        frozen = false;
    }

}
