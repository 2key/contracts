pragma solidity ^0.4.24;

import '../../contracts/openzeppelin-solidity/contracts/ownership/Ownable.sol';
import '../../contracts/2key/libraries/Call.sol';

/*
Taken from https://github.com/HarryR/solcrypto/blob/master/contracts/SECP2561k.sol
Taken from https://github.com/jbaylina/ecsol and https://github.com/1Address/ecsol

License: GPL-3.0
*/


contract SECP2561k {

  uint256 constant public gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 constant public gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 constant public n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;  // p in https://en.bitcoin.it/wiki/Secp256k1
  uint256 constant public a = 0;
  uint256 constant public b = 7;
  uint256 constant public Q = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;  // n in https://en.bitcoin.it/wiki/Secp256k1

  function _jAdd(
    uint256 x1, uint256 z1,
    uint256 x2, uint256 z2)
  public
  pure
  returns(uint256 x3, uint256 z3)
  {
    (x3, z3) = (
    addmod(
      mulmod(z2, x1, n),
      mulmod(x2, z1, n),
      n
    ),
    mulmod(z1, z2, n)
    );
  }

  function _jSub(
    uint256 x1, uint256 z1,
    uint256 x2, uint256 z2)
  public
  pure
  returns(uint256 x3, uint256 z3)
  {
    (x3, z3) = (
    addmod(
      mulmod(z2, x1, n),
      mulmod(n - x2, z1, n),
      n
    ),
    mulmod(z1, z2, n)
    );
  }

  function _jMul(
    uint256 x1, uint256 z1,
    uint256 x2, uint256 z2)
  public
  pure
  returns(uint256 x3, uint256 z3)
  {
    (x3, z3) = (
    mulmod(x1, x2, n),
    mulmod(z1, z2, n)
    );
  }

  function _jDiv(
    uint256 x1, uint256 z1,
    uint256 x2, uint256 z2)
  public
  pure
  returns(uint256 x3, uint256 z3)
  {
    (x3, z3) = (
    mulmod(x1, z2, n),
    mulmod(z1, x2, n)
    );
  }

  function _inverse(uint256 val) public pure
  returns(uint256 invVal)
  {
    uint256 t = 0;
    uint256 newT = 1;
    uint256 r = n;
    uint256 newR = val;
    uint256 q;
    while (newR != 0) {
      q = r / newR;

      (t, newT) = (newT, addmod(t, (n - mulmod(q, newT, n)), n));
      (r, newR) = (newR, r - q * newR );
    }

    return t;
  }

  function _ecAdd(
    uint256 x1, uint256 y1, uint256 z1,
    uint256 x2, uint256 y2, uint256 z2)
  public
  pure
  returns(uint256 x3, uint256 y3, uint256 z3)
  {
    uint256 lx;
    uint256 lz;
    uint256 da;
    uint256 db;

    if (x1 == 0 && y1 == 0) {
      return (x2, y2, z2);
    }

    if (x2 == 0 && y2 == 0) {
      return (x1, y1, z1);
    }

    if (x1 == x2 && y1 == y2) {
      (lx, lz) = _jMul(x1, z1, x1, z1);
      (lx, lz) = _jMul(lx, lz, 3, 1);
      (lx, lz) = _jAdd(lx, lz, a, 1);

      (da,db) = _jMul(y1, z1, 2, 1);
    } else {
      (lx, lz) = _jSub(y2, z2, y1, z1);
      (da, db) = _jSub(x2, z2, x1, z1);
    }

    (lx, lz) = _jDiv(lx, lz, da, db);

    (x3, da) = _jMul(lx, lz, lx, lz);
    (x3, da) = _jSub(x3, da, x1, z1);
    (x3, da) = _jSub(x3, da, x2, z2);

    (y3, db) = _jSub(x1, z1, x3, da);
    (y3, db) = _jMul(y3, db, lx, lz);
    (y3, db) = _jSub(y3, db, y1, z1);

    if (da != db) {
      x3 = mulmod(x3, db, n);
      y3 = mulmod(y3, da, n);
      z3 = mulmod(da, db, n);
    } else {
      z3 = da;
    }
  }

  function _ecDouble(uint256 x1, uint256 y1, uint256 z1) public pure
  returns(uint256 x3, uint256 y3, uint256 z3)
  {
    (x3, y3, z3) = _ecAdd(x1, y1, z1, x1, y1, z1);
  }

  function _ecMul(uint256 d, uint256 x1, uint256 y1, uint256 z1) public pure
  returns(uint256 x3, uint256 y3, uint256 z3)
  {
    uint256 remaining = d;
    uint256 px = x1;
    uint256 py = y1;
    uint256 pz = z1;
    uint256 acx = 0;
    uint256 acy = 0;
    uint256 acz = 1;

    if (d == 0) {
      return (0, 0, 1);
    }

    while (remaining != 0) {
      if ((remaining & 1) != 0) {
        (acx,acy,acz) = _ecAdd(acx, acy, acz, px, py, pz);
      }
      remaining = remaining / 2;
      (px, py, pz) = _ecDouble(px, py, pz);
    }

    (x3, y3, z3) = (acx, acy, acz);
  }

  function ecadd(
    uint256 x1, uint256 y1,
    uint256 x2, uint256 y2)
  public
  pure
  returns(uint256 x3, uint256 y3)
  {
    uint256 z;
    (x3, y3, z) = _ecAdd(x1, y1, 1, x2, y2, 1);
    z = _inverse(z);
    x3 = mulmod(x3, z, n);
    y3 = mulmod(y3, z, n);
  }

  function ecadd2(
    uint256[2] p1,
    uint256[2] p2)
  public
  pure
  returns(uint256[2] memory p3)
  {
    uint256 x3;
    uint256 y3;
    (x3, y3) = ecadd(p1[0],p1[1],p2[0],p2[1]);
    p3[0] = x3;
    p3[1] = y3;
  }

  function ecmul(uint256 x1, uint256 y1, uint256 scalar) public pure
  returns(uint256 x2, uint256 y2)
  {
    uint256 z;
    (x2, y2, z) = _ecMul(scalar, x1, y1, 1);
    z = _inverse(z);
    x2 = mulmod(x2, z, n);
    y2 = mulmod(y2, z, n);
  }


  function point_hash( uint256[2] point )
  public pure returns(address)
  {
    if (point[0] == 0 && point[1] == 0) {
      return address(0);
    }
    return address(uint256(keccak256(abi.encodePacked(point[0], point[1]))) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
  }

  /**
  * hash(s*G + c*B)
  */
  function sbmul_add_mul(uint256 s, uint256[2] B, uint256 c)
  public pure returns(address)
  {
    s = (Q - s) % Q;
    s = mulmod(s, B[0], Q);

    return ecrecover(bytes32(s), B[1] % 2 != 0 ? 28 : 27, bytes32(B[0]), bytes32(mulmod(c, B[0], Q)));
  }

  //
  // Based on the original idea of Vitalik Buterin:
  // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
  // validates that the eliptical point (x1,y1) times scalar is indeed the eliptical point (qx, qy)
  //
  function ecmulVerify(uint256 x1, uint256 y1, uint256 scalar, uint256 qx, uint256 qy) public pure
  returns(bool)
  {
    address signer = sbmul_add_mul(0, [x1, y1], scalar);
    return point_hash([qx, qy]) == signer;
  }
  function ecmulVerify1(uint256[2] x, uint256 scalar, uint256[2] q) public pure
  returns(bool)
  {
    return point_hash(q) == sbmul_add_mul(0, x, scalar);
  }

  function publicKey(uint256 privKey) public pure
  returns(uint256 qx, uint256 qy)
  {
    return ecmul(gx, gy, privKey);
  }

  function publicKeyVerify(uint256 privKey, uint256 x, uint256 y) public pure
  returns(bool)
  {
    return ecmulVerify(gx, gy, privKey, x, y);
  }

  function deriveKey(uint256 privKey, uint256 pubX, uint256 pubY) public pure
  returns(uint256 qx, uint256 qy)
  {
    uint256 z;
    (qx, qy, z) = _ecMul(privKey, pubX, pubY, 1);
    z = _inverse(z);
    qx = mulmod(qx, z, n);
    qy = mulmod(qy, z, n);
  }
}

contract TwoKeySchnorr is SECP2561k, Ownable {
  event Log1iB(string s, uint256 units, bytes b);
  event Log1A(string s, address a);
  event Log1iA(string s, uint i, address a);

  mapping(uint => uint) private Pxs; // x component of #hope => Public of link secret for that hope
  mapping(uint => uint) private Pys; // y component of #hope => Public of link secret for that hope
  uint N; // maximal number of hopes allowed (number of public keys stored in Pxs, Pys)
  mapping(address => mapping(uint => uint)) private convert;  // address(R) => hope => #converstions

  function setPi(uint i, uint Px, uint Py) public onlyOwner
  {
    // set a specific public key of a link secret
//    require(Pxs[i] == 0 && Pys[i] == 0,'P already defined for i');
    require(i == 1 || Pxs[i-1] != 0 || Pys[i-1] != 0,'P not defined for i-1');
    Pxs[i] = Px;
    Pys[i] = Py;
    if (i > N) {
      N = i;
    }
  }

  function setPs(bytes Ps) public onlyOwner
  {
    // set all public keys of all link secrets
    uint i = 1;
    for(uint idx = 0; idx < Ps.length; idx+=64) {
      uint256 Px = Call.loadUint256(Ps,idx);
      uint256 Py = Call.loadUint256(Ps,idx+32);
      setPi(i, Px, Py);
      i++;
    }
  }

  function getPi(uint i) public view
  returns(uint256 x, uint256 y)
  {
    // get the public key of a specific index
    x = Pxs[i];
    y = Pys[i];
    require(x != 0 || y != 0,'P not defined for i');
  }

  function verify(uint256 s, uint256[2] R, uint256[2] P, bytes32 m) public pure
  returns(bool)
  {
    // verify Schnorr signature: s*G = R + m*P
    // gas 39433
    address Ra = point_hash(R);
    uint256 h = uint256(m);
    h = (Q - h) % Q; // -h TODO we can remove this by negating R and not negating s inside sbmul_add_mul
    return Ra == sbmul_add_mul(s, P, h);  // hash(s*G + h*P)
  }

  function verifyQ(bytes Rs, bytes Qs, bytes cuts, uint n) private view
  returns(address[] influencers)
  {
    // verify eliptical points in the array of Rs and their cuts do indeed match the points in the array Qs
    // such that Qs[i] == h(Rs[i]|cuts[i])*P[i]
    // params:
    //   Rs - array of the R values of all the influencers in the link
    //   Q - instead of computing h(R[i]|cut[i])*P[i] the sender needs to supply a precomputed value Qs[i]
    //       and the code will verify that the computation is true
    //   cuts - the cut of each R value in Rs
    //   n - from which hope the R starts
    // returns:
    //   array of fake address of the R,cut pairs (the lower 20 bytes of h(Rs[i]|cuts[i]) )
    require(Rs.length%64 == 0 && Rs.length == Qs.length, 'Rs/Qs bad length');
    influencers = new address[](Rs.length/64);
    uint i = 0;
    for(uint idx = 0; idx < Rs.length; idx+=64) {
      uint256 Rxi = Call.loadUint256(Rs,idx);
      uint256 Qxi = Call.loadUint256(Qs,idx);
      uint256 Ryi = Call.loadUint256(Rs,idx+32);
      uint256 Qyi = Call.loadUint256(Qs,idx+32);
      uint8 cut = Call.loadUint8(cuts,i);

      uint256 h = uint256(keccak256(abi.encodePacked(Rxi,Ryi,cut)));
      influencers[i] = address(h & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      require(ecmulVerify(Pxs[i+n],Pys[i+n],h,Qxi,Qyi),'Qs[i] != h(Rs[i]|cuts[i])*P[i]');

      i++;
    }
  }

  function convertVerify(uint256 s, uint256[2] R, bytes Rs, bytes Qs, address a, bytes cuts) private view
  returns(address[] influencers)
  {
    // verify convertion of a using aggregated signature s, masking R and array of Rs and Qs for all influencers
    // verify s*G = R + hash(R|a)*P[n] + sum Rs + sum Qs
    // n is taken from the length of Rs
    // Qs are the precomputed h(Rs[i]|cuts[i])*P[i] of each influencer
//    address Sa;
    uint256[2] memory S;
    uint n = 1;
//    require(Rs.length%64 == 0 && Rs.length == Qs.length, 'Rs/Qs bad length');
    influencers = new address[](Rs.length/64);
//    uint i = 0;
    for(uint idx = 0; idx < Rs.length; idx+=64) {
//      uint256[2] memory Ri = Call.loadPair(Rs,idx);
//      uint256[2] memory Qi = Call.loadPair(Qs,idx);
//      uint8 cut = Call.loadUint8(cuts,n-1);

      uint256 h = uint256(keccak256(abi.encodePacked(Call.loadPair(Rs,idx),Call.loadUint8(cuts,n-1))));
      influencers[n-1] = address(h & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
//      emit Log1iA('h', idx, point_hash(S));
      h = uint256(keccak256(abi.encodePacked(point_hash(S),h)));  // [uint256(0),uint256(0)] point_hash(S)
      require(ecmulVerify1([Pxs[n],Pys[n]],h,Call.loadPair(Qs,idx)),'Qs[i] != h(Rs[i]|cuts[i])*P[i]');

      S = ecadd2(S, Call.loadPair(Rs,idx));
      S = ecadd2(S, Call.loadPair(Qs,idx));
//      Sa = point_hash(S);

//      i++;
      n++;
    }
    S = ecadd2(S, R);

//    uint n = Rs.length / 64 + 1;
    uint256 Px = Pxs[n];
    uint256 Py = Pys[n];
    require(Px != 0 || Py != 0, 'P not defined for n');

    bytes32 m = keccak256(abi.encodePacked(R,a));

    // verify s*G = R + m*P
    require(verify(s, S, [Px, Py], m), 'signature failed');
  }

  function convertTest(uint256 s, uint256[2] R, bytes Rs, bytes Qs, bytes cuts, address a) public
  {
    // convert user a by using aggregated signature s, masking R and array of Rs, cuts and Qs for all influencers
    // for each influencer 'i' verify Qs[i]=h(Rs[i]|cuts[i])*P[i] and then verify that
    // s*G = R + hash(R|a)*P[n] + sum Rs[i]+h(Rs[i]|cuts[i])*P[i]
    // Qs are the precomputed h(Rs[i]|cuts[i])*P[i] of each influencer
    // the convert count of each influencer 'i' is incremented for hope location 'i+1'
    address[] memory influencers = convertVerify(s, R, Rs, Qs, a, cuts); // verifyQ(Rs, Qs, cuts, 1);

    for(uint i = 0; i < Rs.length>>6; i++) {
      convert[influencers[i]][i+1]++;  // record that Ri|cut contributed to a convertion at hope i
    }
  }

  // dont say its pure so we can measure gas
  function claimTest(uint256[2] R, uint256[2] R_bar, uint256[2] P_bar, uint256[2] Q, address a) public
  {
    // influencer 'a' wants to claim he is associated with R
    // a can be anything that identifies the influencer. address or the ecdsa made by the influencer
    // R_bar, P_bar public of random k_bar, x_bar
    // Q is a precomputed h(R_bar,P_bar,a)*P_bar
    // k = r_bar + h(R_bar,P_bar,a) * x_bar so we validate that
    // R =? R_bar + h(R_bar,P_bar,a) * P_bar or R_bar + Q after verifying that Q is valid
    uint256 h = uint256(keccak256(abi.encodePacked(R_bar,P_bar,a))); // same as abi.encodePacked(R_bar[0],R_bar[1],P_bar[0],P_bar[1],a)
    require(ecmulVerify(P_bar[0],P_bar[1],h,Q[0],Q[1]),'Q != h(R_bar,P_bar,a)*P_bar');
    (R_bar[0], R_bar[1]) = ecadd(R_bar[0], R_bar[1], Q[0], Q[1]);
    require(R_bar[0] == R[0] && R_bar[1] == R[1], 'R!=R_bar+Q');
  }

  function getConvertions(address R_a) public view
  returns(uint)
  {
    // sum how many convertions R has identified by his address R_a
    uint cnt = 0;
    for(uint i = 1; i <= N; i++) {
      cnt += convert[R_a][i];
    }
    return cnt;
  }

/////////// Cache code
  struct SaInfo {
    uint256[2] S;  // s*G of an aggregated signature s
    uint n; // the number of hopes aggregated in s
    address from; // the fake address of the influencer that came before the last
    address influencer; // the fake address of the last influencer that contributed to s
    uint8 cut; // the cut of the last influencer
  }
  mapping(address => SaInfo) public Sa2Info;  // map from Sa, address of S, to a structure

  function getSa2Sxy(address Sa) public view
  returns(bytes32 Sx, bytes32 Sy)
  {
    Sx = bytes32(Sa2Info[Sa].S[0]);
    Sy = bytes32(Sa2Info[Sa].S[1]);
  }

  function getSa(bytes Rs, bytes Qs, address Sa0) public view
  returns(address Sa, uint n)
  {
    // return the Sa, Sn of the last Sa stored in contract
    // Sa starts with Sa0 and add all the following influencers in Rs, each with their precomputed Qs
    uint256[2] memory S;
    if (Sa0 != address(0)) {
      SaInfo info = Sa2Info[Sa0];
      n = info.n;
      S = info.S;
    }

    for(uint idx = 0; idx < Rs.length; idx+=64) {
      S = ecadd2(S, Call.loadPair(Rs,idx));
      S = ecadd2(S, Call.loadPair(Qs,idx));
      Sa = Sa0;
      Sa0 = point_hash(S);
      if (Sa2Info[Sa0].n != n+1) {
        return;
      }
      n++;
    }
    Sa = Sa0;

    return;
  }

  function setSa2Info(bytes Rs, bytes Qs, bytes cuts, address Sa) private
  returns (uint256[2] memory S, uint n, address Sa1)
  {
    // Set all the SaInfo structure starting from pre existing Sa (that was at hope Sn) and then adding elements from:
    // Rs,Qs and cuts (after verifying Qs[i]=h(Rs[i]|cuts[i])*P[i+Sn])
    // computing a new Sa and its new SaInfo
    // returning the last Sa, its hope n, and its address Sa1
    if (Sa != address(0)) {
      SaInfo info = Sa2Info[Sa];
      n = info.n+1;
      S = info.S;
    } else {
//      S[0] = 0;
//      S[1] = 0;
      n = 1;
    }
//    address[] memory influencers = verifyQ(Rs, Qs, cuts, n);
//    address[] memory influencers = new address[](Rs.length/64);

    for(uint idx = 0; idx < Rs.length; idx+=64) {
      uint256[2] memory R = Call.loadPair(Rs,idx);
      uint256[2] memory Q = Call.loadPair(Qs,idx);

      uint256 h = uint256(keccak256(abi.encodePacked(R,Call.loadUint8(cuts,idx/64))));
      address influencer = address(h & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
//      emit Log1iA('Sa last', n, Sa);
      h = uint256(keccak256(abi.encodePacked(Sa,h)));  // address(0x00523e17232fdc5657625128ec06216eb07debe531) [uint256(0),uint256(0)] point_hash(S)
      require(ecmulVerify1([Pxs[n],Pys[n]],h,Q),'Qs[i] != h(Rs[i]|cuts[i])*P[i]');

      S = ecadd2(S, R);
      S = ecadd2(S, Q);
      Sa1 = point_hash(S);
      Sa2Info[Sa1] = SaInfo(S, n, Sa, influencer, uint8(cuts[idx/64]));

      Sa = Sa1;
//      emit Log1iA('Sa next', n, Sa);
      n++;
    }
  }

  function convertTestVerify(uint256 s, uint256[2] S, uint n, bytes32 m) private view
  {
    // verify that s*G =? S + m*P[n]
    uint256 Px = Pxs[n];
    uint256 Py = Pys[n];
    require(Px != 0 || Py != 0, 'P not defined for n');
    require(verify(s, S, [Px, Py], m), 'signature failed');
  }

  function convertTestCache(uint256 s, uint256[2] R, bytes Rs, bytes Qs, bytes cuts, address Sa, address a) public
  {
    // convert user a by using aggregated signature s, masking R and array of Rs, cuts and Qs for all influencers
    // that came after Sa (that was at hope Sn)
    // populate all the SaInfo for all Sa of the influencers in Rs this will verify that Qs[i]=h(Rs[i]|cuts[i])*P[i+Sn]
    // and get the final S (sum of Rs and Qs)
    // and then verify that
    // s*G = R + hash(R|a)*P[n+Sn] + S
    // Qs are the precomputed h(Rs[i]|cuts[i])*P[i] of each influencer
    // the convert count of each influencer 'i' is incremented for hope location 'i+1'
    uint n;
    uint256[2] memory S;
    (S, n, Sa) = setSa2Info(Rs, Qs, cuts, Sa);
    S = ecadd2(S, R);

//    convertTestVerify(s, S, n, keccak256(abi.encodePacked(R,a)));

    while (Sa != address(0)) {
      SaInfo info = Sa2Info[Sa];
      convert[info.influencer][info.n]++;
      Sa = info.from;
    }
  }
}
