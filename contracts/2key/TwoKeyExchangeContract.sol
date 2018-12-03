pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyExchangeContract.sol";
import "./MaintainingPattern.sol";


/**
 * @author Nikola Madjarevic
 * This is going to be the contract on which we will store exchange rates between USD and ETH
 * Will be maintained, and updated by our trusted server and CMC api every 8 hours.
 */
contract TwoKeyExchangeContract is MaintainingPattern, ITwoKeyExchangeContract {

    /**
     * @notice public mapping which will store rate between 1 wei eth and 1 wei fiat currency
     * Will be updated every 8 hours, and it's public
     */
    mapping(bytes32 => uint) public currency2value;

    constructor(address [] _maintainers, address _twoKeyAdmin) MaintainingPattern (_maintainers, _twoKeyAdmin )
    public {

    }
    /**
     * @notice Function where our backend will update the state (rate between eth_wei and dollar_wei) every 8 hours
     * @dev only twoKeyMaintainer address will be eligible to update it
     */
    function setPrice(bytes32 _currency, uint _ETHWei_CurrencyWEI) public onlyMaintainer {
        currency2value[_currency] = _ETHWei_CurrencyWEI;
    }

    /**
     * @notice Function to get price for the selected currency
     * @param _currency is the currency (ex. 'USD', 'EUR', etc.)
     * @return rate between currency and eth wei
     */
    function getPrice(string _currency) public view returns (uint) {
        bytes32 key = stringToBytes32(_currency);
        return currency2value[key];
    }


    /**
     * @notice Helper method to convert string to bytes32
     * @dev If string.length > 32 then the rest after 32nd char will be deleted
     * @return result
     */
    function stringToBytes32(string memory source) returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

}
