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
    //TODO: Rename fiatCurrencyExchangeRateToOneEther
    mapping(bytes32 => FiatCurrency) public currencyName2rate;

    struct FiatCurrency {
        uint rateEth;
        bool isGreater; //Flag which represent if 1 ETH > 1 fiat (ex. 1eth = 120euros) true (1eth = 0.001 BTC) false
    }

    constructor(address [] _maintainers, address _twoKeyAdmin) MaintainingPattern (_maintainers, _twoKeyAdmin )
    public {

    }

    /**
     * @notice Function where our backend will update the state (rate between eth_wei and dollar_wei) every 8 hours
     * @dev only twoKeyMaintainer address will be eligible to update it
     */
    function setPrice(bytes32 _currency, bool _isGreater, uint _ETHWei_CurrencyWEI) public onlyMaintainer {
        FiatCurrency memory f = FiatCurrency ({
            rateEth: _ETHWei_CurrencyWEI,
            isGreater: _isGreater
        });
        currencyName2rate[_currency] = f;
    }

    /**
     * @notice Function to get price for the selected currency
     * @param _currency is the currency (ex. 'USD', 'EUR', etc.)
     * @return rate between currency and eth wei
     */
    function getPrice(string _currency) public view returns (uint,bool) {
        bytes32 key = stringToBytes32(_currency);
        return (currencyName2rate[key].rateEth, currencyName2rate[key].isGreater);
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
