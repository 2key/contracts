pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @notice Contract for storing all our singletone addresses (proxy)
 * @author Nikola Madjarevic
 * Created at 12/23/18
 */
contract TwoKeySingletoneAddressStorage is Ownable {

    mapping(string => address) contractNameToAddress;

    constructor () Ownable() public {

    }

    /**
     * @notice Function to set contract addresses
     * @dev can be called only by owner
     * @param addresses is the array of the addresses
     */
    function setAddresses(address [] addresses) external onlyOwner {
        contractNameToAddress['TwoKeyAdmin'] = addresses[0];
        contractNameToAddress['TwoKeyEventSource'] = addresses[1];
        contractNameToAddress['TwoKeyCongress'] = addresses[2];
        contractNameToAddress['TwoKeyEconomy'] = addresses[3];
        contractNameToAddress['TwoKeyUpgradableExchange'] = addresses[4];
        contractNameToAddress['TwoKeyFixedRateExchange'] = addresses[5];
        contractNameToAddress['TwoKeyRegistry'] = addresses[6];
    }

    /**
     * @notice Function to get address for the selected contract
     * @param contractName is the name of the contract (singleton) we want to get
     * @return address of the requested contract
     */
    function getContractAddress(string contractName) external view returns (address) {
        require(contractNameToAddress[contractName] != address(0));
        return contractNameToAddress[contractName];
    }

    /**
     * @notice Function to change contract address
     * @param _contractName is the name of the contract we're changing address for
     * @param _newAddress is the new address for the contract
     * @dev Can be called only by owner
     */
    function changeOrAddContractAddress(string _contractName, address _newAddress) external onlyOwner {
        contractNameToAddress[_contractName] = _newAddress;
    }

}
