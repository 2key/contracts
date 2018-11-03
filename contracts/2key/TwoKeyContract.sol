pragma solidity ^0.4.24; //We have to specify what version of compiler this code will use

import '../openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './ERC20full.sol';
import './TwoKeyEventSource.sol';
import './Call.sol';

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TwoKeyContract is StandardToken, Ownable {
  event Fulfilled(address indexed to, uint256 units);
  event Rewarded(address indexed to, uint256 amount);
  event Log1(string s, uint256 units);
  event Log1A(string s, address a);


  using SafeMath for uint256;
  // Public variables of the token
//  TwoKeyReg registry;  // 2key admin contract that created this
  TwoKeyEventSource eventSource;

  // address public owner;  // Who created the contract (business) // contained in Ownable.sol
  string public name;
  string public ipfs_hash;
  string public symbol;
  uint8 public decimals = 0;  // ARCs are not divisable
  uint256 public cost; // Cost of product in wei
  uint256 public bounty; // Cost of product in wei
  uint256 public quota;  // maximal tokens that can be passed in transferFrom
  uint256 unit_decimals;  // units being sold can be fractional (for example tokens in ERC20)

  // Private variables of the token
  mapping (address => address) public received_from;
  mapping(address => uint256) public xbalances; // balance of external currency (ETH or 2Key coin)
  mapping(address => uint256) public units; // number of units bought

  // The cut from the bounty each influencer is taking + 1
  // zero (also the default value) indicates default behaviour in which the influencer takes an equal amount as other influencers
  mapping(address => uint256) public influencer2cut;

  function getCuts(address last_influencer) public view returns (uint256[]) {
    address[] memory influencers = getInfluencers(last_influencer);
    uint n_influencers = influencers.length;
    uint256[] memory cuts = new uint256[](n_influencers + 1);
    for (uint i = 0; i < n_influencers; i++) {
      address influencer = influencers[i];
      cuts[i] = influencer2cut[influencer];
    }
    cuts[n_influencers] = influencer2cut[last_influencer];
    return cuts;
  }

  function setCut(uint256 cut) public {
    // the sender sets what is the percentage of the bounty s/he will receive when acting as an influencer
    // the value 255 is used to signal equal partition with other influencers
    // A sender can set the value only once in a contract
    require(cut <= 100 || cut == 255);
    require(influencer2cut[msg.sender] == 0);
    if (cut <= 100) {
      cut++;
    }
    influencer2cut[msg.sender] = cut;
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFromQuota(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), '_to already has ARCs');
    require(_value <= balances[_from], '_from does not have enough ARCs');
    require(_value <= allowed[_from][msg.sender], 'sender not allowed');

    balances[_from] = balances[_from].sub(_value);
//    uint256 v = _value.mul(quota);
//    uint256 w = balanceOf(_to);
//    uint256 x = w.add(v);
    balances[_to] = balances[_to].add(_value.mul(quota));
    totalSupply_ = totalSupply_.add(_value.mul(quota.sub(1)));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(received_from[_to] == 0, '_to already has ARCs');
    require(_from != address(0), '_from does not have ARCs');
    allowed[_from][msg.sender] = 1;
    if (transferFromQuota(_from, _to, _value)) {
      if (received_from[_to] == 0) {
        // inform the 2key admin contract, once, that an influencer has joined
        if (eventSource != address(0)) {
          eventSource.joined(this, _from, _to);
        }
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
        if (eventSource != address(0)) {
          eventSource.joined(this, msg.sender, _to);
        }
      }
      received_from[_to] = msg.sender;
      return true;
    } else {
      return false;
    }
  }

  // New 2Key method

  function getConstantInfo() public view returns (string,string,uint256,uint256,uint256,address,string,uint256) {
    return (name,symbol,cost,bounty,quota,owner,ipfs_hash,unit_decimals);
  }

  function total_units() public view returns (uint256);

  function getDynamicInfo(address me) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
    // address(this).balance is solidity reserved word for the the ETH amount deposited in the contract
    return (balanceOf(me),units[me],xbalances[me],totalSupply_,address(this).balance,total_units(),influencer2cut[me]);
  }

  // function () external payable {
  //   buyProduct();
  // }

  // buy product. if you dont have ARCs then first take them (join) from _from
  function buyFrom(address _from) public payable {
    require(_from != address(0));
    address _to = msg.sender;
    if (balanceOf(_to) == 0) {
      transferFrom(_from, _to, 1);
    }
    buyProduct();
  }

  function redeem() public {
    address influencer = msg.sender;
    uint256 b = xbalances[influencer];
    require(b > 0);
    if (b > address(this).balance) {
      b = address(this).balance;
    }
    xbalances[influencer] = xbalances[influencer].sub(b);
    if(!influencer.send(b)){
       revert();
    }
  }

  // low level product purchase function
  function buyProduct() public payable;

  function getInfluencers(address customer) public view returns (address[]) {
    // build a list of all influencers from converter back to to contractor
    // dont count the conveter and contractr themselves
    address influencer = customer;
    // first count how many influencers
    uint n_influencers = 0;
    while (true) {
      influencer = received_from[influencer];
      require(influencer != address(0),'not connected to contractor');
      if (influencer == owner) {
        break;
      }
      n_influencers++;
    }
    // allocate temporary memory to hold the influencers
    address[] memory influencers = new address[](n_influencers);
    // fill the array of influencers in reverse order, from the last influencer just before the converter to the
    // first influencer just after the contractor
    influencer = customer;
    while (n_influencers > 0) {
      influencer = received_from[influencer];
      n_influencers--;
      influencers[n_influencers] = influencer;
    }

    return influencers;
  }

  function buyProductInternal(uint256 _units, uint256 _bounty) public payable {
    // buy coins with cut
    // low level product purchase function
    address customer = msg.sender;
    emit Log1A('customer',customer);
    uint256 customer_balance = balanceOf(customer);
    emit Log1('customer_balance', customer_balance);
    require(customer_balance > 0);

    uint256 _total_units = total_units();
    emit Log1('_total_units',_total_units);

    require(_units > 0);
    require(_total_units >= _units);
    address[] memory influencers = getInfluencers(customer);
    uint n_influencers = influencers.length;
    emit Log1('n_influencers',n_influencers);

    // distribute bounty to influencers
    uint256 total_bounty = 0;
    for (uint i = 0; i < n_influencers; i++) {
      address influencer = influencers[i];  // influencers is in reverse order
      uint256 b;
      if (i == n_influencers-1) {  // if its the last influencer then all the bounty goes to it.
        b = _bounty;
      } else {
        uint256 cut = influencer2cut[influencer];
        //        emit Log("CUT", influencer, cut);
        if (cut > 0 && cut <= 101) {
          b = _bounty.mul(cut.sub(1)).div(100);
        } else {  // cut == 0 or 255 indicates equal particine of the bounty
          b = _bounty.div(n_influencers-i);
        }
      }
      xbalances[influencer] = xbalances[influencer].add(b);
      emit Rewarded(influencer, b);
      total_bounty = total_bounty.add(b);
      _bounty = _bounty.sub(b);
    }

    // all that is left from the cost is given to the owner for selling the product
    xbalances[owner] = xbalances[owner].add(msg.value).sub(total_bounty); // TODO we want the cost of a token to be fixed?
    units[customer] = units[customer].add(_units);

    emit Fulfilled(customer, units[customer]);
  }

}

contract TwoKeyAcquisitionContract is TwoKeyContract
{
  uint256 public _total_units; // total number of units on offer

  // Initialize all the constants
  constructor(TwoKeyEventSource _eventSource, string _name, string _symbol,
        uint256 _tSupply, uint256 _quota, uint256 _cost, uint256 _bounty,
        uint256 _units, string _ipfs_hash) public {
    require(_bounty <= _cost);
    // owner = msg.sender;  // done in Ownable()
    // We do an explicit type conversion from `address`
    // to `TwoKeyReg` and assume that the type of
    // the calling contract is TwoKeyReg, there is
    // no real way to check that.
    name = _name;
    symbol = _symbol;
    totalSupply_ = _tSupply;
    balances[owner] = _tSupply;
    cost = _cost;
    bounty = _bounty;
    quota = _quota;
    _total_units = _units;
    ipfs_hash = _ipfs_hash;
    unit_decimals = 0;  // dont allow fractional units

    received_from[owner] = owner;  // allow owner to buy from himself

    if (_eventSource != address(0)) {
      eventSource = _eventSource;
      eventSource.created(this, owner);
    }
  }

  function total_units() public view returns (uint256) {
    return _total_units;
  }

  // low level product purchase function
  function buyProduct() public payable {
    // caluclate the number of units being purchased
    uint _units = msg.value.div(cost);
    require(msg.value == cost * _units);
    // bounty is the cost of a single token. Compute the bounty for the units
    // we are buying
    uint256 _bounty = bounty.mul(_units);

    buyProductInternal(_units, _bounty);

    _total_units = _total_units.sub(_units);
  }
}

contract TwoKeyPresellContract is TwoKeyContract {
  ERC20full public erc20_token_sell_contract;

//  address dc;

  // Initialize all the constants
  constructor(TwoKeyEventSource _eventSource, string _name, string _symbol,
        uint256 _tSupply, uint256 _quota, uint256 _cost, uint256 _bounty,
        string _ipfs_hash, ERC20full _erc20_token_sell_contract) public {
    require(_bounty <= _cost);
    // owner = msg.sender;  // done in Ownable()
    // We do an explicit type conversion from `address`
    // to `TwoKeyReg` and assume that the type of
    // the calling contract is TwoKeyReg, there is
    // no real way to check that.
    name = _name;
    symbol = _symbol;
    totalSupply_ = _tSupply;
    balances[owner] = _tSupply;
    cost = _cost;
    bounty = _bounty;
    quota = _quota;
    ipfs_hash = _ipfs_hash;
    received_from[owner] = owner;  // allow owner to buy from himself
    if (_eventSource != address(0)) {
      eventSource = _eventSource;
      eventSource.created(this, owner);
    }

    if (_erc20_token_sell_contract != address(0)) {
      // fractional units are determined by the erc20 contract
      erc20_token_sell_contract = _erc20_token_sell_contract;  // ERC20full()
      unit_decimals = Call.params0(erc20_token_sell_contract, "decimals()");
//      emit Log1('start_unit_decimals', unit_decimals); // does not work in constructor on geth
      require(unit_decimals >= 0);
      require(unit_decimals <= 18);
    }
  }

  function total_units() public view returns (uint256) {
    uint256 _total_units;
//    _total_units = erc20_token_sell_contract.balanceOf(address(this));
    _total_units = Call.params1(erc20_token_sell_contract, "balanceOf(address)",uint(this));
    return _total_units;
  }

  // low level product purchase function

  function buyProduct() public payable {
    emit Log1('unit_decimals', unit_decimals);
//    unit_decimals = 18; // uint256(erc20_token_sell_contract.decimals());
    // cost is the cost of a single token. Each token has 10**decimals units
    uint256 _units = msg.value.mul(10**unit_decimals).div(cost);
    emit Log1('units', _units);
    // bounty is the cost of a single token. Compute the bounty for the units
    // we are buying
    uint256 _bounty = bounty.mul(_units).div(10**unit_decimals);
    emit Log1('_bounty', _bounty);

    buyProductInternal(_units, _bounty);

    emit Log1('going to transfer', _units);

//    erc20_token_sell_contract.transfer(msg.sender, _units);  // TODO is this dangerous!?
    require(address(erc20_token_sell_contract).call(bytes4(keccak256("transfer(address,uint256)")),msg.sender,_units));
  }
}
