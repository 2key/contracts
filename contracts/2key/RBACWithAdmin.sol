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
  string public constant ROLE_CONTROLLER = "controller";


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
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
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

  /// @notice Function will revert if user doesn't have controller role
  /// @return bool returns true if user has controller role.
  function onlyControllerRole() public view returns (bool) {
    checkRole(msg.sender, ROLE_CONTROLLER);
    return true;
  }

  function getAdminRole() public view returns (string) {
    return ROLE_ADMIN;
  }
  function getControllerRole() public view returns (string) {
    return ROLE_CONTROLLER;
  }
}
