pragma solidity ^0.4.24; //We have to specify what version of compiler this code will use

import "../openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol";
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './ERC20full.sol';
import './TwoKeyEventSource.sol';
import './TwoKeyReg.sol';
import './Call.sol';

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TwoKeyContract is BasicToken, Ownable {
  event Fulfilled(address indexed to, uint256 units);
  event Rewarded(address indexed to, uint256 amount);
  event Log1(string s, uint256 units);
  event Log1A(string s, address a);


  using SafeMath for uint256;
  // Public variables of the token
  TwoKeyReg registry;
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
  mapping(address => uint256) internal influencer2cut;

  function getCuts(address last_influencer) public view returns (uint256[]) {
    address[] memory influencers = getInfluencers(last_influencer);
    uint n_influencers = influencers.length;
    uint256[] memory cuts = new uint256[](n_influencers + 1);
    for (uint i = 0; i < n_influencers; i++) {
      address influencer = influencers[i];
      cuts[i] = cutOf(influencer);
    }
    cuts[n_influencers] = cutOf(last_influencer);
    return cuts;
  }

  function setCut(uint256 cut) public {
    // the sender sets what is the percentage of the bounty s/he will receive when acting as an influencer
    // the value 255 is used to signal equal partition with other influencers
    // A sender can set the value only once in a contract
    require(cut <= 100 || cut == 255);
    require(influencer2cut[msg.sender] == 0, 'cut not zero');
    if (registry != address(0)) {
      address plasma_owner = registry.ethereum2plasma(msg.sender);
      require(influencer2cut[plasma_owner] == 0, 'plasma cut not zero');
      address eth_owner = registry.plasma2ethereum(msg.sender);
      require(influencer2cut[eth_owner] == 0, 'eth cut not zero');
    }
    influencer2cut[msg.sender] = cut;
  }
  function cutOf(address _owner) public view returns (uint256) {
    uint256 b = influencer2cut[_owner];
    if (b == 0 && registry != address(0)) {
      address plasma_owner = registry.ethereum2plasma(_owner);
      b = influencer2cut[plasma_owner];
      if (b != 0) {
        return b;
      }
      address eth_owner = registry.plasma2ethereum(_owner);
      b = influencer2cut[eth_owner];
    }
    return b;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  // TODO change this function from public to internal if you dont want people to join without a 2key link
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_value == 1, 'can only transfer 1 ARC');
    require(_from != address(0), '_from undefined');
    require(_to != address(0), '_to undefined');
    require(received_from[_to] == 0, '_to already has ARCs');
    if (registry != address(0)) {
      address plasma_to = registry.ethereum2plasma(_to);
      require(received_from[plasma_to] == 0, 'plasma _to already has ARCs');
      address eth_to = registry.plasma2ethereum(_to);
      require(received_from[eth_to] == 0, 'eth _to already has ARCs');

      if (balances[_from] == 0) {
        address plasma_from = registry.ethereum2plasma(_from);
        if (balances[plasma_from] > 0) {
          _from = plasma_from;
        } else {
          address eth_from = registry.plasma2ethereum(_from);
          require(balances[eth_from] > 0,'_from does not have arcs');
          _from = eth_from;
        }
      }
    }

    balances[_from] = balances[_from].sub(1);
    balances[_to] = balances[_to].add(quota);
    totalSupply_ = totalSupply_.add(quota.sub(1));

    emit Transfer(_from, _to, 1);
    if (received_from[_to] == 0) {
      // inform the 2key admin contract, once, that an influencer has joined
      if (eventSource != address(0)) {
        eventSource.joined(this, _from, _to);
      }
    }
    received_from[_to] = _from;
    return true;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(false, 'not implemented');
    return false;
  }

  // New 2Key method

  function getConstantInfo() public view returns (string,string,uint256,uint256,uint256,address,string,uint256) {
    return (name,symbol,cost,bounty,quota,owner,ipfs_hash,unit_decimals);
  }

  function total_units() public view returns (uint256);

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    uint256 b = balances[_owner];
    if (registry != address(0)) {
      address plasma_owner = registry.ethereum2plasma(_owner);
      b += balances[plasma_owner];
      address eth_owner = registry.plasma2ethereum(_owner);
      b += balances[eth_owner];
    }
    return b;
  }
  function xbalanceOf(address _owner) public view returns (uint256) {
    uint256 b = xbalances[_owner];
    if (registry != address(0)) {
      address plasma_owner = registry.ethereum2plasma(_owner);
      b += xbalances[plasma_owner];
      address eth_owner = registry.plasma2ethereum(_owner);
      b += xbalances[eth_owner];
    }
    return b;
  }

  function getDynamicInfo(address me) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
    // address(this).balance is solidity reserved word for the the ETH amount deposited in the contract
    return (balanceOf(me),units[me],xbalanceOf(me),totalSupply_,address(this).balance,total_units(),cutOf(me));
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
    uint256 b0 = xbalances[influencer];

    uint256 b1 = 0;
    if (registry != address(0)) {
      address influencer_plasma = registry.ethereum2plasma(influencer);
      if (influencer_plasma != address(0)) {
        b1 = xbalances[influencer_plasma];
      }
    }

    uint256 b = b0.add(b1);
    if (b == 0) {
      return;
    }

    uint256 bmax = address(this).balance;
    if (bmax == 0) {
      return;
    }
    if (b0 > bmax) {
      b0 = bmax;
      b1 = 0;
      b = bmax;
    } else if (b > bmax) {
      b1 = bmax.sub(b0);
      b = bmax;
    }

    xbalances[influencer] = xbalances[influencer].sub(b0);
    if (b1 > 0) {
      xbalances[influencer_plasma] = xbalances[influencer_plasma].sub(b1);
    }

    if(!influencer.send(b)) {
       revert("failed to send");
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
    require(balanceOf(customer) > 0,"no arcs");

    uint256 _total_units = total_units();
//    emit Log1('_total_units',_total_units);

    require(_units > 0,"no units requested");
    require(_total_units >= _units,"not enough units available in stock");
    address[] memory influencers = getInfluencers(customer);
    uint n_influencers = influencers.length;

    // distribute bounty to influencers
    uint256 total_bounty = 0;
    for (uint i = 0; i < n_influencers; i++) {
      address influencer = influencers[i];  // influencers is in reverse order
      uint256 b;
      if (i == n_influencers-1) {  // if its the last influencer then all the bounty goes to it.
        b = _bounty;
      } else {
        uint256 cut = cutOf(influencer);
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
  constructor(TwoKeyReg _reg, TwoKeyEventSource _eventSource, string _name, string _symbol,
        uint256 _tSupply, uint256 _quota, uint256 _cost, uint256 _bounty,
        uint256 _units, string _ipfs_hash) public {
    require(_bounty <= _cost,"bounty bigger than cost");
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
    if (_reg != address(0)) {
      registry = _reg;
    }
  }

  function total_units() public view returns (uint256) {
    return _total_units;
  }

  // low level product purchase function
  function buyProduct() public payable {
    // caluclate the number of units being purchased
    uint _units = msg.value.div(cost);
    require(msg.value == cost * _units, "ethere sent does not divide equally into units");
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
  constructor(TwoKeyReg _reg, TwoKeyEventSource _eventSource, string _name, string _symbol,
        uint256 _tSupply, uint256 _quota, uint256 _cost, uint256 _bounty,
        string _ipfs_hash, ERC20full _erc20_token_sell_contract) public {
    require(_bounty <= _cost,"bounty bigger than cost");
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
    if (_reg != address(0)) {
      registry = _reg;
    }

    if (_erc20_token_sell_contract != address(0)) {
      // fractional units are determined by the erc20 contract
      erc20_token_sell_contract = _erc20_token_sell_contract;  // ERC20full()
      unit_decimals = Call.params0(erc20_token_sell_contract, "decimals()");
//      emit Log1('start_unit_decimals', unit_decimals); // does not work in constructor on geth
      require(unit_decimals >= 0,"unit decimals to low");
      require(unit_decimals <= 18,"unit decimals to big");
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
//    emit Log1('unit_decimals', unit_decimals);
//    unit_decimals = 18; // uint256(erc20_token_sell_contract.decimals());
    // cost is the cost of a single token. Each token has 10**decimals units
    uint256 _units = msg.value.mul(10**unit_decimals).div(cost);
//    emit Log1('units', _units);
    // bounty is the cost of a single token. Compute the bounty for the units
    // we are buying
    uint256 _bounty = bounty.mul(_units).div(10**unit_decimals);
//    emit Log1('_bounty', _bounty);

    buyProductInternal(_units, _bounty);

//    emit Log1('going to transfer', _units);
//    emit Log1A('coin', address(erc20_token_sell_contract));

//    erc20_token_sell_contract.transfer(msg.sender, _units);  // TODO is this dangerous!?
    require(address(erc20_token_sell_contract).call(bytes4(keccak256("transfer(address,uint256)")),msg.sender,_units),
      "failed to send coins");
  }
}
