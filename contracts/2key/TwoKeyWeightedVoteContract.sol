pragma solidity ^0.4.24;
import './TwoKeyContract.sol';
import './TwoKeySignedContract.sol';

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

  function transferSig(bytes sig) public returns (address) {
    // must use a sig which includes a cut (ie by calling free_join_take in sign.js
    require((sig.length-20) % (65+41) == 0, 'signature does not include cut of last vote');
    // validate sig AND populate received_from and influencer2cut
    address last_voter = super.transferSig(sig);

    address[] memory voters = getInfluencers(last_voter);

    uint n_voters = voters.length;

    for (uint i = 0; i < n_voters+1; i++) {
      address influencer;
      if (i < n_voters) {
        influencer = voters[i];
      } else {
        influencer = last_voter;
      }

      if (voted[influencer]) {
        continue;
      }
      voted[influencer] = true;
      uint256 cut = influencer2cut[influencer];
      if (cut > 0) { // if cut == 0 then influencer did not vote at all
        nvotes++;
        if (cut <= 101) {
          voted_yes += cut-1;
        } else if (154 < cut && cut < 255) {
          voted_no += 255-cut;
        } // if cut == 255 then abstain
      }
    }

    return last_voter;
  }
}
