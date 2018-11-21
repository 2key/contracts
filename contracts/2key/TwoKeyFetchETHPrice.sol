pragma solidity ^0.4.24;

import "../../installed_contracts/oraclize-api/contracts/usingOraclize.sol";


//SINGLETON
contract TwoKeyFetchETHPrice is usingOraclize {

    string public ETHUSD;
    event LogConstructorInitiated(string nextStep);
    event LogPriceUpdated(string price);
    event LogNewOraclizeQuery(string description);

    constructor() payable {
        emit LogConstructorInitiated("Constructor was initiated. Call 'updatePrice()' to send the Oraclize Query.");
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();
        ETHUSD = result;
        emit LogPriceUpdated(result);
    }

    function getPriceUint() public view returns (uint) {
        return parseInt(ETHUSD);
    }

    function updatePrice() payable {
        if (oraclize_getPrice("URL") > this.balance) {
            emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query("URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price");
        }
    }
}
