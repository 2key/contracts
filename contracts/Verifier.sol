pragma solidity ^0.4.14;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal returns (G1Point) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal returns (G2Point) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.add(p.negate()) should be zero.
    function negate(G1Point p) internal returns (G1Point) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function add(G1Point p1, G1Point p2) internal returns (G1Point r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid }
        }
        require(success);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.mul(1) and p.add(p) == p.mul(2) for all points p.
    function mul(G1Point p, uint s) internal returns (G1Point r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] p1, G2Point[] p2) internal returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2,
            G1Point d1, G2Point d2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    function verifyingKey() internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0x23c85440efd6a3358a4d659eb8bfc8e343660e07dd5a91e3eaed2141559f1b03, 0xf4fd7db0dd2a1ed18c4c67543d8f967cc06eef8b12300c1ea44825eaf40ba89], [0x12a97e2aae17a5994a349366f9f9c0018e690833b458564c167e6a662678034e, 0xbabdc62a8a96f224ec41c889c5411a4fc8100a0bc0d9588684b07e2bc26c2f9]);
        vk.B = Pairing.G1Point(0x21bc2d51942d95d50fdd7a2d422d5d505dc02d1189f14abb54057fa7dee15513, 0x29015677d3caac3fb46a284e9717c48b259a0f21ce9a0841a70aca6993f7a17c);
        vk.C = Pairing.G2Point([0x2c97550d0c6ba43530c09d9e0d02893ecce674ac42e4023fb426f980e24d9186, 0x121be3b03d03227581ea6ca3763ccb569c4cf638d5a2cfa124fb6ae3e8991fdc], [0x1363b41af1354eaacacf6e77d9a7b3a822dfb4572938d7e645c22a9b61da0967, 0x138d65de0657a8bc7ebc52d7b5ea9fb664b1895bf95941eeb264177c4bdd21cd]);
        vk.gamma = Pairing.G2Point([0x4a5fe80867265984db1af7bc1d84f44c94558a6ece6b96bfff546a466bc2fb4, 0x1cdbaa4d5d09fa76984eaae182797e3c1ab81b1d0b6ceeeeed2eb3c7823d5f08], [0xa9c8730de11d7cc0760d145bf14ebd339da7d6e0e7faec311cedfbf54c29f1a, 0x2c77c8bb7f2fe460ec5a73a35eef868de58631850638b9c288c7242316e8165]);
        vk.gammaBeta1 = Pairing.G1Point(0x239ba6cd363a416b2305c59aa3974aac1b8ad1334bd502fd1ffe49ee72928112, 0xc14f109527a7ecbb80e74b508a01a36389ec5902930c044565737d21c9ee826);
        vk.gammaBeta2 = Pairing.G2Point([0x12b6680121bfe9aa22a834258ef3920b9d1bc4ebfefd02e907c86c8cc70a6804, 0xfbb1e95207fec6800bd4aee4f521a2aa2e84b6275fb42607908e99221bea4d5], [0x5d0a32557c0ed2c55e5e4665e7641c1a5867428ad0275915be5d3dad58f2ee0, 0x10423e67df722ab02ca83274042d7db3350dc06a9b1b5bd16aff997f45f93a75]);
        vk.Z = Pairing.G2Point([0x2820c36266cb83aa255755adf983b6d2095c612b218a1008047ab1cd5fe2d517, 0x1cd317f0217a680faf0bf263411982d233d76879258b5cd96afcdd16cfc0df9d], [0x16dff705142f3d58806e979443c3a822bb2cdf608e4b02bec42381fa2b03c228, 0x180757660f64177d50907a80e0aff2aacfa600f360f28e923adf10591a5b8348]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x2af573f20f324dcfc40525cce5fd95ae84963ab7388acf91fd0f905dcb21580f, 0xf08e945c5893dbe9c38219fdbf152eec8456517c4ad25e965c774d63905e9cd);
        vk.IC[1] = Pairing.G1Point(0xcd65661069ef1dc98d88ae1c140f743a3da8717d23a34a5c6b9665ac5083233, 0x14bebb6a3abfca32a5b5b8e59aea3a57e4b759b30db1d123dc762260fc4c24d1);
        vk.IC[2] = Pairing.G1Point(0x18059a99e5174367eeff0ffd2b07c71b5f989ec0d80ffec08b4e7b6ff99bc2b8, 0x1024dcc7e7ca578886ccb2659232970f2ded17fc63c4bfaa539c5583fdefdb6);
        vk.IC[3] = Pairing.G1Point(0x19b7a3f11ed7cec5dcf69bd8c24c69b9eb9b68e72382232d4b8e2574f6a6fba0, 0x19fc7c37566f126f61053efb8ee8606a26ee62f2ca724ba40be47f1e6fe550a0);
        vk.IC[4] = Pairing.G1Point(0x2f5b4af4e97084b66ee5073c6fcfb0430ac97c661bd6323752bfb77784f8a505, 0x2a679891e8f0c07675f45de3b4c9a436d62a045abd47059f511214977a055c59);
        vk.IC[5] = Pairing.G1Point(0x14095d954c7cbf8ff7b0a9849fe95b96cea8053d83241a8911ad493b9fb042ad, 0xb89905e3b4c117070fb3ac965a6d2e9fb3d90cc78dd0ea0f1e0949f1c4b6c5e);
    }
    function verify(uint[] input, Proof proof) internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.add(vk_x, Pairing.mul(vk.IC[i + 1], input[i]));
        vk_x = Pairing.add(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.add(vk_x, Pairing.add(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.add(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    event Verified(string);
    function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[5] input
        ) returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }

    int public success_count = 0;
    int public failure_count = 0;
    bool public success = false;
    function test_verify(
        uint[2] a,
        uint[2] a_p,
        uint[2][2] b,
        uint[2] b_p,
        uint[2] c,
        uint[2] c_p,
        uint[2] h,
        uint[2] k,
        uint[5] input) public {
        // Verifiy the proof
        success = verifyTx(a, a_p, b, b_p, c, c_p, h, k, input);
        if (success) {
            // Proof verified
            success_count += 1;
        } else {
            // Sorry, bad proof!
            failure_count += 1;
        }
    }
}