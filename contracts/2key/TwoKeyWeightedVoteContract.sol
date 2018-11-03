pragma solidity ^0.4.24;
import './TwoKeyContract.sol';
import './TwoKeySignedContract.sol';
import './Call.sol';

contract TwoKeyWeightedVoteContract is TwoKeySignedPresellContract {
  constructor(TwoKeyEventSource _eventSource, string _name, string _symbol,
    uint256 _tSupply, uint256 _quota, uint256 _cost, uint256 _bounty,
    string _ipfs_hash, ERC20full _erc20_token_sell_contract)
  public
  TwoKeySignedPresellContract(_eventSource,_name,_symbol,_tSupply,_quota,_cost,_bounty,_ipfs_hash,_erc20_token_sell_contract)
  {
  }

  mapping(address => bool)  public voted;
  uint public nvotes;
  uint public voted_yes;
  uint public voted_no;
  uint public weighted_yes;
  uint public weighted_no;

  function transferSig(bytes sig) public returns (address[]) {
    // must use a sig which includes a cut (ie by calling free_join_take in sign.js
    require((sig.length-21) % (65+1+65+20) == 0, 'signature is not version 1 and/or does not include cut of last vote');
    // validate sig AND populate received_from and influencer2cut
    address[] memory voters = super.transferSig(sig);

    for (uint i = 0; i < voters.length; i++) {
      address influencer = voters[i];

      if (voted[influencer]) {
        continue;
      }
      voted[influencer] = true; // TODO count how much vote token the influencer already transfered for this vote
      // extract the vote (yes/no) and the weight of the vote from cut
      uint256 cut = influencer2cut[influencer];
      if (cut > 0) { // if cut == 0 then influencer did not vote at all
        nvotes++;
        bool yes;
        uint256 weight;
        if (cut <= 101) {
          yes = true;
          voted_yes++;
          weight = cut-1;
        } else if (154 < cut && cut < 255) {
          yes = false;
          voted_no++;
          weight = 255-cut;
        } else { // if cut == 255 then abstain
          weight = 0;
        }

        if (weight > 0) {
          uint tokens = weight.mul(cost);
          // make sure weight is not more than number of coins influencer has
          uint _units = Call.params1(erc20_token_sell_contract, "balanceOf(address)",uint(influencer));
          if (_units < tokens) {
            tokens = _units;
          }
          // make sure weight is not more than what coins allows owner to take
          uint _allowance = Call.params2(erc20_token_sell_contract, "allowance(address,address)",uint(influencer),uint(owner)); // BUG it should be msg.sender and not owner
          if (_allowance < tokens) {
            tokens = _allowance;
          }
          // vote
          if (tokens > 0) {
            weight = tokens.div(cost);
            if (yes) {
              weighted_yes += weight;
            } else {
              weighted_no += weight;
            }
            // transfer coins from influncer to owner in the amount of the weight used for voting
            require(address(erc20_token_sell_contract).call(bytes4(keccak256("transferFrom(address,address,uint256)")),influencer,owner,tokens));
          }
        }
      }
    }

    return voters;
  }
}