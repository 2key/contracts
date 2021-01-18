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

    event OracleDeployed(
        address oracleAddress,
        string oracleDescription
    );

    address [] deployedOracles;
    bytes32 [] deployedOraclesDescriptions;

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

    function deployAndStoreOracles(
        uint8 decimals,
        bytes32 [] oraclesDescription,
        uint256 version
    )
    public
    {
        uint i = 0;

        for(i = 0; i < oraclesDescription.length; i++) {
            string memory description = bytes32ToStr(oraclesDescription[i]);

            address deployedOracle = new MockChainLinkOracle(
                decimals,
                description,
                version,
                address(this)
            );

            emit OracleDeployed(
                deployedOracle,
                description
            );

            deployedOracles.push(deployedOracle);
            deployedOraclesDescriptions.push(oraclesDescription[i]);

            pairToOracleAddress[oraclesDescription[i]] = deployedOracle;
        }

    }

    function bytes32ToStr(bytes32 _bytes32) public pure returns (string) {

        // string memory str = string(_bytes32);
        // TypeError: Explicit type conversion not allowed from "bytes32" to "string storage pointer"
        // thus we should fist convert bytes32 to bytes (to dynamically-sized byte array)

        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }


    function getDeployedOraclesAndDescriptions()
    public
    view
    returns (address[], bytes32[]) {
        return (
        deployedOracles,
        deployedOraclesDescriptions
        );
    }


}
