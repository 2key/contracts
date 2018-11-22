pragma solidity ^0.4.24;

/**
 * Registry storage contract - currently not exapandable
 * @author Nikola Madjarevic
 * Using proxy pattern to support upgradability
*/

contract TwoKeyRegistryStorage {
    /// mapping user's address to user's name
    mapping(address => string) public address2username;
    /// mapping user's name to user's address
    mapping(bytes32 => address) public username2currentAddress;
    // mapping username to array of addresses he is using/used
    mapping(bytes32 => address[]) public username2AddressHistory;
    /*
        mapping address to wallet tag
        wallet tag = username + '_' + walletname
    */
    mapping(address => bytes32) public address2walletTag;

    // reverse mapping from walletTag to address
    mapping(bytes32 => address) public walletTag2address;

    // plasma address => ethereum address
    // note that more than one plasma address can point to the same ethereum address so it is not critical to use the same plasma address all the time for the same user
    // in some cases the plasma address will be the same as the ethereum address and in that case it is not necessary to have an entry
    // the way to know if an address is a plasma address is to look it up in this mapping
    mapping(address => address) public plasma2ethereum;

    struct UserData {
        string username;
        string fullName;
        string email;
    }

    mapping(address => UserData) addressToUserData;

    /*
        Those mappings are for the fetching data about in what contracts user participates in which role
    */

    /// mapping users address to addresses of campaigns where he is contractor
    mapping(address => address[]) userToCampaignsWhereContractor;

    /// mapping users address to addresses of campaigns where he is moderator
    mapping(address => address[]) userToCampaignsWhereModerator;

    /// mapping users address to addresses of campaigns where he is refferer
    mapping(address => address[]) userToCampaignsWhereReferrer;

    /// mapping users address to addresses of campaigns where he is converter
    mapping(address => address[]) userToCampaignsWhereConverter;

    /// Address of 2key event source contract which will have permission to write on this contract
    /// (Address is enough, there is no need to spend sufficient gas and instantiate whole contract)
    address public twoKeyEventSource;

    /// Address for contract maintainer
    /// Should be the array of addresses - will have permission on some of the mappings to update
    address[] maintainers;

    address twoKeyAdminContractAddress;

}
