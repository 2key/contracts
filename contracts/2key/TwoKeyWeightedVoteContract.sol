pragma solidity ^0.4.24;
import './TwoKeyContract.sol';
import './TwoKeySignedContract.sol';

contract TwoKeyWeightedVoteContract is TwoKeySignedPresellContract {
  mapping(address => bool)  public voted;
  uint public nvotes;
  uint public voted_yes;
  uint public voted_no;

  function voteSign(bytes sig) public {
    // must use a sig which includes a cut (ie by calling free_join_take in sign.js
    require(sig.length % (65+41) == 0, 'signature does not include cut of last vote');
    // validate sig AND populate received_from and influencer2cut
    transferSig(sig);

    address customer = msg.sender;

    address[] memory influencers = getInfluencers(customer);

    uint n_influencers = influencers.length;

    for (uint i = 0; i < n_influencers+1; i++) {
      address influencer;
      if (i < n_influencers) {
        influencer = influencers[i];
      } else {
        influencer = customer;
      }

      if (voted[influencer]) {
        continue;
      }
      voted[influencer] = true;
      nvotes++;
      uint256 cut = influencer2cut[influencer];


      if (cut < 128) {
        voted_yes += cut;
      } else if (cut < 256) {
        voted_no += cut - 128;
      }
    }
  }
}
