pragma solidity ^0.4.18; //We have to specify what version of compiler this code will use

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

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
  TwoKeyAdmin creator;  // 2key admin contract that created this
  address public owner;  // Who created the contract (business)
  string public name;
  string public ipfs_hash;
  string public symbol;
  uint8 public decimals = 18;
  uint256 public cost; // Cost of product in wei
  uint256 public bounty; // Cost of product in wei
  uint256 public quota;  // maximal tokens that can be passed in transferFrom
  uint256 public total_units; // total number of units on offer
  uint256 private nonce;

  // Private variables of the token
  mapping (address => address) internal received_from;
  mapping(address => uint256) internal xbalances; // balance of external currency (ETH or 2Key coin)
  mapping(address => uint256) internal units; // number of units bought

  event Fulfilled(address indexed to, uint256 nonce);

  // Initialize all the constants
  function TwoKeyContract(address _owner, string _name, string _symbol,
        uint256 _tSupply, uint256 _quota, uint256 _cost, uint256 _bounty,
        uint256 _units, string _ipfs_hash) public {
    require(_bounty <= _cost);
    // We do an explicit type conversion from `address`
    // to `TwoKeyAdmin` and assume that the type of
    // the calling contract is TwoKeyAdmin, there is
    // no real way to check that.
    creator = TwoKeyAdmin(msg.sender);
    owner = _owner;
    name = _name;
    symbol = _symbol;
    totalSupply_ = _tSupply;
    balances[_owner] = _tSupply;
    cost = _cost;
    bounty = _bounty;
    quota = _quota;
    total_units = _units;
    ipfs_hash = _ipfs_hash;

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
    totalSupply_ = totalSupply_ + _value * (quota - 1);
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
    totalSupply_ = totalSupply_ + _value * (quota - 1);
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
    allowed[_from][msg.sender] = 1;
    if (transferFromQuota(_from, _to, _value)) {
      if (received_from[_to] == 0) {
        // inform the 2key admin contract, once, that an influencer has joined
        creator.joinedContract(_to, this);
      }
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
      if (received_from[_to] == 0) {
        // inform the 2key admin contract, once, that an influencer has joined
        creator.joinedContract(_to, this);
      }
      received_from[_to] = msg.sender;
      return true;
    } else {
      return false;
    }
  }

  // New 2Key method
  // function getInfo(address me) public view returns (uint256,uint256,uint256,string,string,uint256,uint256,uint256,uint256,uint256,uint256,address) {
  //   return (this.balanceOf(me),units[me],xbalances[me],name,symbol,cost,bounty,quota,totalSupply_,total_units,this.balance,owner);
  // }
  //
  function getConstantInfo() public view returns (string,string,uint256,uint256,uint256,uint256,address,string) {
    return (name,symbol,cost,bounty,quota,total_units,owner,ipfs_hash);
  }

  function getDynamicInfo(address me) public view returns (uint256,uint256,uint256,uint256,uint256) {
    return (this.balanceOf(me),units[me],xbalances[me],totalSupply_,this.balance);
  }

  function () external payable {
    buyProduct();
  }

  function buyFrom(address _from) public payable {
    require(_from != address(0));
    address _to = msg.sender;
    if (this.balanceOf(_to) == 0) {
      transferFrom(_from, _to, 1);
    }
    buyProduct();
  }

  // low level token purchase function
  function buyProduct() public payable {
    address customer = msg.sender;
    require(this.balanceOf(customer) > 0);
    require(msg.value == cost);
    require(total_units > 0);

    // distribute bounty to influencers
    uint n_influencers = 0;
    address influencer = customer;
    while (true) {
        influencer = received_from[influencer];
        if (influencer == owner) {
            break;
        }
        n_influencers = n_influencers + 1;
    }
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
    total_units = total_units.sub(1);
    units[customer] = units[customer].add(1);

    Fulfilled(msg.sender, nonce);
    nonce = nonce + 1;
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
       revert();
    }
  }
}

contract TwoKeyAdmin {
  mapping(address => string) public owner2name;
  mapping(bytes32 => address) public name2owner;
  uint256 public nonce;

  function addName(string _name) public {
    address _owner = msg.sender;
    // check if name is taken
    if (name2owner[keccak256(_name)] != 0) {
      revert();
    }
    // remove previous name
    bytes memory last_name = bytes(owner2name[_owner]);
    if (last_name.length != 0) {
      name2owner[keccak256(owner2name[_owner])] = 0;
    }
    owner2name[_owner] = _name;
    name2owner[keccak256(_name)] = _owner;
  }

  function getName2Owner(string _name) public view returns (address) {
    return name2owner[keccak256(_name)];
  }
  function getOwner2Name(address _owner) public view returns (string) {
    return owner2name[_owner];
  }

  event Created(address indexed owner, address c, uint256 nonce);
  function createTwoKeyContract(string _name, string _symbol, uint256 _totalSupply, uint256 _quota, uint256 _cost, uint256 _bounty, uint256 _units, string _ipfs_hash) public returns (address) {
    address _owner = msg.sender;
    address c = (new TwoKeyContract(_owner, _name, _symbol, _totalSupply, _quota, _cost, _bounty, _units, _ipfs_hash));

    Created(_owner, c, nonce);
    nonce = nonce + 1;
    return c;
  }

  event Joined(address indexed influencer, address c, uint256 nonce);
  function joinedContract(address influencer, address c) {
    Joined(influencer, c, nonce);
    nonce = nonce + 1;
  }

  // function fundtransfer(address etherreceiver, uint256 amount) public {
  //     if(!etherreceiver.send(amount)){
  //        revert();
  //     }
  // }
  // faulback for receiving ETH
  // function() public payable { }
}
