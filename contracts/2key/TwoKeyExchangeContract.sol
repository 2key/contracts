pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyExchangeContract.sol";


/**
 * @author Nikola Madjarevic
 * This is going to be the contract on which we will store exchange rates between USD and ETH
 * Will be maintained, and updated by our trusted server and CMC api every 8 hours.
 */
contract TwoKeyExchangeContract is ITwoKeyExchangeContract {

    /**
     * @notice public variable which will store rate between 1 wei eth and 1 wei dollar
     * Will be updated every 8 hours, and it's public
     */
    uint EthWEI_UsdWEI;

    /**
     * Mapping which will store maintainers who are eligible to update contract state
     */
    mapping(address => bool) public isMaintainer;


    address public twoKeyAdmin;


    modifier onlyMaintainer {
        require(isMaintainer[msg.sender] == true);
        _;
    }

    modifier onlyTwoKeyAdmin {
        require(msg.sender == address(twoKeyAdmin));
        _;
    }

    constructor(address [] _maintainers, address _twoKeyAdmin) public {
        twoKeyAdmin = _twoKeyAdmin;
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice Function which can add new maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function addMaintainers(address [] _maintainers) public onlyTwoKeyAdmin {
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice Function which can remove some maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function removeMaintainers(address [] _maintainers) public onlyTwoKeyAdmin {
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = false;
        }
    }

    /**
     * @notice Function where our backend will update the state (rate between eth_wei and dollar_wei) every 8 hours
     * @dev only twoKeyMaintainer address will be eligible to update it
     */
    function setPrice(uint _EthWEI_UsdWEI) public onlyMaintainer {
        EthWEI_UsdWEI = _EthWEI_UsdWEI;
    }

    /**
     * @notice Function to get actual rate how much is 1 wei worth $ weis
     * @return EthWEI_UsdWEI value
     */
    function getPrice() public view returns (uint) {
        return EthWEI_UsdWEI;
    }

}
