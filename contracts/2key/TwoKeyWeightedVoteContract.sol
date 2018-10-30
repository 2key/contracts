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

//  function recover(bytes32 hash, bytes sig, uint idx) public returns (address) {
//    // The signature format is a compact form of:
//    //   {bytes32 r}{bytes32 s}{uint8 v}
//    // Compact means, uint8 is not padded to 32 bytes.
//    idx += 32;
//    bytes32 r;
//    assembly
//    {
//      r := mload(add(sig, idx))
//    }
//
//    idx += 32;
//    bytes32 s;
//    assembly
//    {
//      s := mload(add(sig, idx))
//    }
//
//    idx += 1;
//    uint8 v;
//    assembly
//    {
//      v := mload(add(sig, idx))
//    }
//    if (v <= 1) v += 27;
//    require(v==27 || v==28,'bad sig v');
//    return ecrecover(hash, v, r, s);
//  }

//  function recover_cut(uint8 cut, bytes sig, uint idx) public returns (address) {
//    bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to plasma address")),keccak256(abi.encodePacked(msg.sender))));
//
//    idx += 32;
//    bytes32 r;
//    assembly
//    {
//      r := mload(add(sig, idx))
//    }
//
//    idx += 32;
//    bytes32 s;
//    assembly
//    {
//      s := mload(add(sig, idx))
//    }
//
//    idx += 1;
//    uint8 v;
//    assembly
//    {
//      v := mload(add(sig, idx))
//    }
//    if (v >= 32) {
//      v -= 32;
//      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
//      hash = keccak256(abi.encodePacked(prefix, hash));
//    }
//    if (v <= 1) v += 27;
//    require(v==27 || v==28,'bad sig v');
//    return ecrecover(hash, v, r, s);
//
//  }

//  function transferSig1(bytes sig) public returns (address) {
//    // TODO keep same as code in TwoKeyPlasmaEvents.sol:visited
//    // move ARCs based on signature information
//    // returns the last address in the sig
//
//    // sig structure:
//    // 20 bytes are the address of the contractor or the influencer who created sig.
//    //  this is the "anchor" of the link
//    //  It must have a public key aleady stored for it in public_link_key
//    // Begining of a loop on steps in the link:
//    // 65 bytes are step-signature using the secret from previous step
//    // next is the message of the step that is going to be hashed and used to compute the above step-signature.
//    // message length depend on version:
//    //  1 byte cut (percentage) each influencer takes from the bounty. the cut is stored in influencer2cut
//    //  65 bytes signature made by the influencer of its cut, the address computed from the signature is then used as before to compute the step signature
//    //  20 bytes public key of the last secret
//    uint idx = 0;
//
//    address old_address;
//    if (idx+20 <= sig.length) {
//      idx += 20;
//      assembly
//      {
//        old_address := mload(add(sig, idx))
//      }
//    }
//
//    address old_public_link_key = public_link_key[old_address];
//    require(old_public_link_key != address(0),'no public link key');
//
//    while (idx + 65 <= sig.length) {
//      uint idx0 = idx;
//      // idx was increased by 65
//      idx += 65;
//
//      bytes32 hash;
//      address new_public_key;
//      address new_address;
//      if (idx + 86 <= sig.length) {  // its  a < and not a <= because we dont want this to be the final iteration for the converter
//        uint8 bounty_cut;
//        {
//          idx += 1;
//          assembly
//          {
//            bounty_cut := mload(add(sig, idx))
//          }
//          require(bounty_cut > 0,'bounty/weight not defined (1..255)');  // 255 are used to indicate default (equal part) behaviour
//        }
//
//        {
//          new_address = recover_cut(bounty_cut, sig, idx);
//          idx += 65;
//        }
//
//        idx += 20;
//        assembly
//        {
//          new_public_key := mload(add(sig, idx))
//        }
//
//        {
//          // update (only once) the cut used by each influencer
//          // we will need this in case one of the influencers will want to start his own off-chain link
//          if (influencer2cut[new_address] == 0) {
//            influencer2cut[new_address] = uint256(bounty_cut);
//          } else {
//            require(influencer2cut[new_address] == uint256(bounty_cut),'bounty cut can not be modified');
//          }
//        }
//
//        // TODO Updating the public key of influencers may not be a good idea because it will require the influencers to use
//        // a deterministic private/public key in the link and this might require user interaction (MetaMask signature)
//        // TODO a possible solution is change public_link_key to address=>address[]
//        // update (only once) the public address used by each influencer
//        // we will need this in case one of the influencers will want to start his own off-chain link
//        if (public_link_key[new_address] == 0) {
//          public_link_key[new_address] = new_public_key;
//        } else {
//          require(public_link_key[new_address] == new_public_key,'public key can not be modified');
//        }
//
//        hash = keccak256(abi.encodePacked(bounty_cut, new_public_key, new_address));
//
//        // check if we exactly reached the end of the signature. this can only happen if the signature
//        // was generated with free_join_take and in this case the last part of the signature must have been
//        // generated by the caller of this method
//        if (idx == sig.length) {
//          require(new_address == msg.sender || owner == msg.sender,'only the contractor or the last in the link can call transferSig');
//        }
//      } else {
//        // handle short signatures generated with free_take
//        // signed message for the last step is the address of the converter
//        new_address = msg.sender;
//        hash = keccak256(abi.encodePacked(new_address));
//      }
//      // assume users can take ARCs only once... this could be changed
//      if (received_from[new_address] == 0) {
//        transferFrom(old_address, new_address, 1);
//      } else {
//        require(received_from[new_address] == old_address,'only tree ARCs allowed');
//      }
//
//      // check if we received a valid signature
//      address signer = recover(hash, sig, idx0);
//      require (signer == old_public_link_key, 'illegal signature');
//      old_public_link_key = new_public_key;
//      old_address = new_address;
//    }
//    require(idx == sig.length,'illegal message size');
//
//    return old_address;
//  }

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
      voted[influencer] = true;
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
          uint _allowance = Call.params2(erc20_token_sell_contract, "allowance(address,address)",uint(influencer),uint(owner));
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