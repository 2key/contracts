pragma solidity ^0.4.18; //We have to specify what version of compiler this code will use

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import './ERC20full.sol';
import './TwoKeyReg.sol';

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TwoKeyContract is StandardToken {
  event Fulfilled(address indexed to, uint256 units);

  using SafeMath for uint256;
  // Public variables of the token
  TwoKeyReg registry;  // 2key admin contract that created this
  address public owner;  // Who created the contract (business)
  string public name;
  string public ipfs_hash;
  string public symbol;
  uint8 public decimals = 0;  // ARCs are not divisable
  uint256 public cost; // Cost of product in wei
  uint256 public bounty; // Cost of product in wei
  uint256 public quota;  // maximal tokens that can be passed in transferFrom

  // Private variables of the token
  mapping (address => address) internal received_from;
  mapping(address => uint256) internal xbalances; // balance of external currency (ETH or 2Key coin)
  mapping(address => uint256) internal units; // number of units bought

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
        registry.joinedContract(_to);
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
        registry.joinedContract(_to);
      }
      received_from[_to] = msg.sender;
      return true;
    } else {
      return false;
    }
  }

  // New 2Key method

  // name,symbol,cost,bounty,quota,total_units,owner,ipfs_hash
  function getConstantInfo() public view returns (string,string,uint256,uint256,uint256,address,string) {
    return (name,symbol,cost,bounty,quota,owner,ipfs_hash);
  }

  function getDynamicInfo(address me) public view returns (uint256,uint256,uint256,uint256,uint256,uint256);

  function () external payable {
    buyProduct();
  }

  // buy product. if you dont have ARCs then first take them (join) from _from
  function buyFrom(address _from) public payable {
    require(_from != address(0));
    address _to = msg.sender;
    if (this.balanceOf(_to) == 0) {
      transferFrom(_from, _to, 1);
    }
    buyProduct();
  }

  // low level product purchase function
  function buyProduct() public payable;

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

contract TwoKeyAcquisitionContract is TwoKeyContract
{
  uint256 public total_units; // total number of units on offer

  // Initialize all the constants
  function TwoKeyAcquisitionContract(address _registry, string _name, string _symbol,
        uint256 _tSupply, uint256 _quota, uint256 _cost, uint256 _bounty,
        uint256 _units, string _ipfs_hash) public {
    require(_bounty <= _cost);
    owner = msg.sender;
    // We do an explicit type conversion from `address`
    // to `TwoKeyReg` and assume that the type of
    // the calling contract is TwoKeyReg, there is
    // no real way to check that.
    registry = TwoKeyReg(_registry);
    name = _name;
    symbol = _symbol;
    totalSupply_ = _tSupply;
    balances[owner] = _tSupply;
    cost = _cost;
    bounty = _bounty;
    quota = _quota;
    total_units = _units;
    ipfs_hash = _ipfs_hash;

    received_from[owner] = owner;  // allow owner to buy from himself

    registry.createdContract(owner);
  }

  function getDynamicInfo(address me) public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
    return (this.balanceOf(me),units[me],xbalances[me],totalSupply_,this.balance,total_units);
  }

  // low level product purchase function
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

    Fulfilled(msg.sender, units[customer]);
  }
}

contract TwoKeyPresellContract is TwoKeyContract {
  ERC20full public erc20_token_sell_contract;
  uint256 erc20_token_sell_contract_decimals;

  // Initialize all the constants
  function TwoKeyPresellContract(address _registry, string _name, string _symbol,
        uint256 _tSupply, uint256 _quota, uint256 _cost, uint256 _bounty,
        string _ipfs_hash, address _erc20_token_sell_contract) public {
    require(_bounty <= _cost);
    owner = msg.sender;
    // We do an explicit type conversion from `address`
    // to `TwoKeyReg` and assume that the type of
    // the calling contract is TwoKeyReg, there is
    // no real way to check that.
    registry = TwoKeyReg(_registry);
    name = _name;
    symbol = _symbol;
    totalSupply_ = _tSupply;
    balances[owner] = _tSupply;
    cost = _cost;
    bounty = _bounty;
    quota = _quota;
    ipfs_hash = _ipfs_hash;
    received_from[owner] = owner;  // allow owner to buy from himself
    registry.createdContract(owner);

    erc20_token_sell_contract = ERC20full(_erc20_token_sell_contract);
    erc20_token_sell_contract_decimals = uint256(erc20_token_sell_contract.decimals());  // TODO is this safe?
    require(erc20_token_sell_contract_decimals >= 0);
    require(erc20_token_sell_contract_decimals <= 18);
  }

  function total_units() public view returns (uint256) {
    uint256 _total_units;
    _total_units = erc20_token_sell_contract.balanceOf(address(this));
    _total_units = _total_units / (10 ** erc20_token_sell_contract_decimals);
    return _total_units;
  }

  function getDynamicInfo(address me) public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
    uint256 _total_units = total_units();
    return (this.balanceOf(me),units[me],xbalances[me],totalSupply_,this.balance,_total_units);
  }

  // low level product purchase function
  function buyProduct() public payable {
    address customer = msg.sender;
    require(this.balanceOf(customer) > 0);
    uint256 _total_units;
    _total_units = erc20_token_sell_contract.balanceOf(address(this));

    // cost is the cost of a single token. Each token has 10**decimals units
    uint256 _units = msg.value.mul(10**erc20_token_sell_contract_decimals).div(cost);
    require(_total_units >= _units);
    // bounty is the cost of a single token. Compute the bounty for the units
    // we are buying
    uint256 _bounty = bounty.mul(_units).div(10**erc20_token_sell_contract_decimals);

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
        uint256 b = _bounty.div(n_influencers);
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
    xbalances[owner] = xbalances[owner].add(cost).sub(total_bounty); // TODO we want the cost of a token to be fixed
    units[customer] = units[customer].add(_units);

    Fulfilled(msg.sender, units[customer]);

    erc20_token_sell_contract.transfer(customer,_units);  // TODO is this dangerous!?
  }
}
