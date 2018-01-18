pragma solidity ^0.4.18; //We have to specify what version of compiler this code will use

import 'zeppelin-solidity/contracts/token/StandardToken.sol';

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TwoKeyContract is StandardToken {
  using SafeMath for uint256;
  // Public variables of the token
  address public owner;  // Who created the contract (business)
  string public name;
  string public symbol;
  uint8 public decimals = 18;
  uint256 public cost; // Cost of product in wei
  uint256 public bounty; // Cost of product in wei
  uint256 public quota;  // maximal tokens that can be passed in transferFrom

  // Private variables of the token
  mapping (address => address) internal received_from;
  mapping(address => uint256) internal xbalances; // balance of external currency (ETH or 2Key coin)

  // Initialize all the constants
  function TwoKeyContract(address _owner, string _name, string _symbol, uint256 _totalSupply, uint256 _quota, uint256 _cost, uint256 _bounty) public {
    require(_bounty <= _cost);
    owner = _owner;
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;
    balances[_owner] = _totalSupply;
    cost = _cost;
    bounty = _bounty;
    quota = _quota;

    received_from[owner] = owner;  // allow owner to buy from himself
  }

  // Modified 2Key method

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transferQuota(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value * quota);
    totalSupply = totalSupply + _value * (quota - 1);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFromQuota(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value * quota);
    totalSupply = totalSupply + _value * (quota - 1);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(received_from[_to] == 0);
    require(_from != address(0));
    allowed[_from][_to] = 1;
    if (transferFromQuota(_from, _to, _value)) {
      received_from[_to] = _from;
      return true;
    } else {
      return false;
    }
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(received_from[_to] == 0);
    if (transferQuota(_to, _value)) {
      received_from[_to] = msg.sender;
      return true;
    } else {
      return false;
    }
  }

  // New 2Key method
  function getInfo(address me) public constant returns (uint256,uint256,string,string,uint256,uint256,uint256,uint256,uint256) {
    return (this.balanceOf(me),xbalances[me],name,symbol,cost,bounty,quota,totalSupply,this.balance);
  }

  function () external payable {
    buyProduct();
  }

  event Log(uint index);
  // low level token purchase function
  function buyProduct() public payable {
    Log(0);
    address customer = msg.sender;
    require(this.balanceOf(customer) > 0);
    require(msg.value == cost);
    Log(1);
    // distribute bounty to influencers
    uint n_influencers = 0;
    address influencer = customer;
    while (true) {
        influencer = received_from[influencer];
        Log(2);
        if (influencer == owner) {
          Log(3);
            break;
        }
        n_influencers = n_influencers + 1;
    }
    Log(4);
    uint256 total_bounty = 0;
    if (n_influencers > 0) {
        uint256 b = bounty.div(n_influencers);
        influencer = customer;
        while (true) {
          influencer = received_from[influencer];
          if (influencer == owner) {
            break;
          }
          xbalances[influencer] = xbalances[influencer].add(b);
          total_bounty = total_bounty.add(b);
        }
    }

    // all that is left from the cost is given to the owner for selling the product
    xbalances[owner] = xbalances[owner].add(cost).sub(total_bounty);
  }

  function redeem() public {
    address influencer = msg.sender;
    uint256 b = xbalances[influencer];
    require(b > 0);
    if (b > this.balance) {
      b = this.balance;
    }
    xbalances[influencer] = xbalances[influencer].sub(b);
    if(!influencer.send(b)){
       throw;
    }
  }
}

contract TwoKeyAdmin {
  // mapping from TwoKeyContract creator (business) to all its contracts
  mapping(address => uint) public ownerNContracts;
  mapping(address => address[]) public owner2Contracts;
  address[] public owners;
  uint public nowners;
  address[] public contracts;
  uint public ncontracts;

  function createTwoKeyContract(string _name, string _symbol, uint256 _totalSupply, uint256 _quota, uint256 _cost, uint256 _bounty) public {
    address _owner = msg.sender;
    address c = (new TwoKeyContract(_owner, _name, _symbol, _totalSupply, _quota, _cost, _bounty));
    if (ownerNContracts[_owner] == 0) {
      owners.push(_owner);
      nowners += 1;
    }
    owner2Contracts[_owner].push(c);
    ownerNContracts[_owner] += 1;
    contracts.push(c);
    ncontracts += 1;
  }

  function getContract(address owner, uint idx) public constant returns (address) {
    return owner2Contracts[owner][idx];
  }

  function getOwner2Contracts(address owner) public constant returns (address[]) {
    return owner2Contracts[owner];
  }

  function getContracts() public constant returns (address[]) {
    return contracts;
  }

  function getOwners() public constant returns (address[]) {
    return owners;
  }

  function fundtransfer(address etherreceiver, uint256 amount){
      if(!etherreceiver.send(amount)){
         throw;
      }
  }
  // faulback for receiving ETH
  function() public payable { }

}
