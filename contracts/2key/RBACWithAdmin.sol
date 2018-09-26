pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/access/rbac/RBAC.sol';


/**
 * @title RBACWithAdmin
 * @author Matt Condon (@Shrugs)
 * @dev It's recommended that you define constants in the contract,
 * like ROLE_ADMIN below, to avoid typos.
 * @notice RBACWithAdmin is probably too expansive and powerful for your
 * application; an admin is actually able to change any address to any role
 * which is a very large API surface. It's recommended that you follow a strategy
 * of strictly defining the abilities of your roles
 * and the API-surface of your contract.
 * This is just an example for example's sake.
 */
contract RBACWithAdmin is RBAC {
  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = "admin";

    // TODO: Finish this include this 4 roles delete controller @nikola
    //TODO: As far as I can remember this are roles we have (??)
  string public constant ROLE_CONTRACTOR = "contractor";
  string public constant ROLE_MODERATOR = "moderator";
  string public constant ROLE_REFERRER = "referrer";
  string public constant ROLE_CONVERTER = "converter";

  address private adminAddress;
  /**
   * @dev modifier to scope access to admins
   * // reverts
   */
  modifier onlyAdmin() {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }
    // @notice Modifier which will revert if msg.sender is not contractor
    modifier onlyContractor() {
        checkRole(msg.sender, ROLE_CONTRACTOR);
        _;
    }

    // @notice Modifier which will revert if msg.sender is not moderator
    modifier onlyModerator() {
        checkRole(msg.sender, ROLE_MODERATOR);
        _;
    }

    // @notice Modifier which will revert if msg.sender is not referrer
    modifier onlyReferrer() {
        checkRole(msg.sender, ROLE_REFERRER);
        _;
    }

    // @notice Modifier which will revert if msg.sender is not converter
    modifier onlyConverter() {
        checkRole(msg.sender, ROLE_CONVERTER);
        _;
    }

  /**
   * @dev constructor. Sets msg.sender as admin by default
   */
 constructor(address _twoKeyAdmin)
    public
  {
    if (_twoKeyAdmin == address(0)) {
      adminAddress = msg.sender;
    } else {
      adminAddress = _twoKeyAdmin;      
    }
    addRole(adminAddress, ROLE_ADMIN);
  }
  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }


  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }



  function getAdminRole() public view returns (string) {
    return ROLE_ADMIN;
  }
  function getContractorRole() public view returns (string) {
      return ROLE_CONTRACTOR;
  }
  function getConverterRole() public view returns (string) {
      return ROLE_CONVERTER;
  }
  function getModeratorRole() public view returns (string) {
      return ROLE_MODERATOR;
  }
  function getReferrerRole() public view returns (string) {
      return ROLE_REFERRER;
  }
}
