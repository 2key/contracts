pragma solidity ^0.4.24;

import "./MockChainLinkOracle.sol";
import "../2key/non-upgradable-singletons/ITwoKeySingletonUtils.sol";


/**
 * MochOraclesManager contract.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract MockOraclesManager is ITwoKeySingletonUtils {

    mapping (bytes32 => address) public pairToOracleAddress;

    struct Oracle {
        bytes32 pair;
        address oracleAddress;
    }

    Oracle [] public oracles;

    event PriceUpdated(
        address oracleAddress,
        bytes32 pair,
        uint timestamp,
        uint rate
    );

    // Sets the _twoKeySingletonRegistry address, used for the deployment
    constructor(
        address _twoKeySingletonRegistry
    )
    public
    {
        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
    }


    // Only maintainer can update the rates
    function updateRates(
        bytes32 [] currenciesPairs,
        uint [] rates
    )
    public
    onlyMaintainer
    {
        uint i;

        for(i = 0; i < currenciesPairs.length; i++) {
            address oracle = pairToOracleAddress[currenciesPairs[i]];

            // If this rate exists
            if(oracle != address(0)) {
                MockChainLinkOracle(oracle).updatePrice(int(rates[i]));

                // Emit event
                emit PriceUpdated(
                    oracle,
                    currenciesPairs[i],
                    block.timestamp,
                    rates[i]
                );
            }
        }
    }

    function storeOracles(
        bytes32 [] pairsRepresentingOracle,
        address [] oracles
    )
    public
    onlyMaintainer
    {
        uint i;

        for(i = 0; i < oracles.length; i++) {
            Oracle memory o = Oracle(
                pairsRepresentingOracle[i],
                oracles[i]
            );
            oracles.push(o);
            pairToOracleAddress[pairsRepresentingOracle[i]] = oracles[i];
        }
    }

}
