import {exchangeRates} from "../../constants/smallConstants";

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

import {expect} from 'chai';
import 'mocha';
import web3Switcher from "../../helpers/web3Switcher";
import {TwoKeyProtocol} from "../../../src";
import getTwoKeyProtocol from "../../helpers/twoKeyProtocol";
import {promisify} from "../../../src/utils/promisify";

import Sign from "../../../src/sign";
const {env} = process;

const timeout = 60000;


describe(
    'TwoKeyParticipationMiningRewards test',
    () => {
        let from: string;
        let twoKeyProtocol: TwoKeyProtocol;
        let signature: string;

        before(
            function () {
                this.timeout(timeout);

                const {web3, address} = web3Switcher.buyer();

                from = address;
                twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_BUYER);
            }
        );

        // Epoch id
        let epochId;
        // Pick 6 users to submit in the epoch
        let usersInEpoch;
        // Generate random rewards for the users
        let  userRewards;

        it('should register participation mining epoch', async () => {

            usersInEpoch = [
                "0xf3c7641096bc9dc50d94c572bb455e56efc85412",
                "0xebadf86c387fe3a4378738dba140da6ce014e974",
                "0xec8b6aaee825e0bbc812ca13e1b4f4b038154688",
                "0xfc279a3c3fa62b8c840abaa082cd6b4073e699c8",
                "0xc744f2ddbca85a82be8f36c159be548022281c62",
                "0x1b00334784ee0360ddf70dfd3a2c53ccf51e5b96"
            ];

            // Set user rewards
            userRewards = [
                parseFloat(twoKeyProtocol.Utils.toWei(Math.floor(Math.random() * 20)).toString()),
                parseFloat(twoKeyProtocol.Utils.toWei(Math.floor(Math.random() * 20)).toString()),
                parseFloat(twoKeyProtocol.Utils.toWei(Math.floor(Math.random() * 20)).toString()),
                parseFloat(twoKeyProtocol.Utils.toWei(Math.floor(Math.random() * 20)).toString()),
                parseFloat(twoKeyProtocol.Utils.toWei(Math.floor(Math.random() * 20)).toString()),
                parseFloat(twoKeyProtocol.Utils.toWei(Math.floor(Math.random() * 20)).toString()),
            ];


            epochId = parseInt(await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getLatestEpochId,[]),10) + 1;
            let txHash = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.registerParticipationMiningEpoch,
                [
                    epochId,
                    usersInEpoch,
                    userRewards,
                    {
                        from: twoKeyProtocol.plasmaAddress
                    }
                ]
            );

            await twoKeyProtocol.Utils.getTransactionReceiptMined(
                await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.finalizeEpoch,
                [
                    epochId,
                    {
                        from: twoKeyProtocol.plasmaAddress
                    }
                ]),
                {web3: twoKeyProtocol.plasmaWeb3}
            );

            let isEpochFinalized = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.isEpochRegistrationFinalized,[epochId]);

            expect(isEpochFinalized).to.be.equal(true);
        }).timeout(timeout);

        it('should check that total submitted for epoch is equaling sum of all rewards', async() => {

            let totalRewardsForEpoch = userRewards.reduce((a,b) => a+b,0);
            let totalRewardsForEpochFromContract = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getTotalRewardsPerEpoch,[epochId]);

            expect(totalRewardsForEpoch).to.be.equal(parseFloat(totalRewardsForEpochFromContract));
        }).timeout(timeout);

        it('should check that user balances per this epoch are properly set', async() => {
            // Iterate through all users
            for(let i=0; i<usersInEpoch.length; i++) {
                // Get user earnings per epoch
                let userRewardsPerEpochFromContract = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getUserEarningsPerEpoch,[usersInEpoch[i],epochId]);
                // Expect to be same as the submitted value
                expect(parseFloat(userRewardsPerEpochFromContract)).to.be.equal(userRewards[i]);

                let userPendingEpochIds = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getPendingEpochsForUser,[usersInEpoch[i]]);
                // Convert big numbers to uint
                userPendingEpochIds = userPendingEpochIds.map((element) => {return parseInt(element,10)});
                // Expect that the last pending epoch id is the on submitted now.
                expect(userPendingEpochIds[userPendingEpochIds.length-1]).to.be.equal(epochId);
            }
        }).timeout(timeout);

        it('should sign user rewards and user address by maintainer', async() => {
            let user = usersInEpoch[2];
            let [pending,withdrawn] = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getUserTotalPendingAndWithdrawn,[user]);

            // Convert to 64 places hex
            let pendingHex = twoKeyProtocol.Utils.toHex(pending);
            pendingHex = pendingHex.slice(2);

            while(pendingHex.length < 64) {
                pendingHex = '0' + pendingHex;
            }

            pendingHex = '0x' + pendingHex;

            // Generate signature
            signature = await Sign.sign_userRewards(
                twoKeyProtocol.plasmaWeb3,
                user,
                pendingHex.toString(),
                twoKeyProtocol.plasmaAddress
            );

            // Recover the message signer
            let messageSigner = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.recoverSignature,[
                user,
                pending.toString(),
                signature
            ]);


            // Assert that the message is signed by proper address
            expect(messageSigner).to.be.equal(twoKeyProtocol.plasmaAddress);
        }).timeout(timeout);

        it('should submit signature for specific user and check state changes', async() => {
            let user = usersInEpoch[2];
            let [pending,withdrawn] = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getUserTotalPendingAndWithdrawn,[user]);

            // Convert to string representation of big number
            pending = pending.toString();

            let userPendingEpochsBefore = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getPendingEpochsForUser,[user]);
            let userWithdrawnEpochsBefore = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getWithdrawnEpochsForUser,[user]);

            userPendingEpochsBefore = userPendingEpochsBefore.map((element) => {return parseInt(element,10)});
            userWithdrawnEpochsBefore = userWithdrawnEpochsBefore.map((element) => {return parseInt(element,10)});


            // Submit signature
            let txHash = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.submitSignatureForUserWithdrawal,[
                user,
                pending,
                signature,
                {
                    from: twoKeyProtocol.plasmaAddress,
                }
            ]);

            await new Promise(resolve => setTimeout(resolve, 2000));

            let userPendingEpochsAfter = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getPendingEpochsForUser,[user]);
            let userWithdrawnEpochsAfter = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getWithdrawnEpochsForUser,[user]);

            userPendingEpochsAfter = userPendingEpochsAfter.map((element) => {return parseInt(element,10)});
            userWithdrawnEpochsAfter = userWithdrawnEpochsAfter.map((element) => {return parseInt(element,10)});

            let amountInProgressOfWithdrawal = await twoKeyProtocol.TwoKeyParticipationMiningPool.getHowMuchUserHaveInProgressOfWithdrawal(user);

            // Assert that amount which was pending is now in progress of withdrawal
            expect(amountInProgressOfWithdrawal).to.be.equal(parseFloat(twoKeyProtocol.Utils.fromWei(pending,'ether').toString()));

            // Get pending rewards again
            [pending,withdrawn] = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getUserTotalPendingAndWithdrawn,[user]);

            // Assert that pending rewards are now 0
            expect(parseInt(pending.toString())).to.be.equal(0);
            // Require that pending epochs after to be 0
            expect(userPendingEpochsAfter.length).to.be.equal(0);
            // Require that all pending are now withdrawn
            expect(userWithdrawnEpochsAfter.length).to.be.equal(userWithdrawnEpochsBefore.length + userPendingEpochsBefore.length);
        }).timeout(timeout);

        it('should assert that signature on contract is same as signature generated', async() => {
            let user = usersInEpoch[2];
            let signatureOnContract = await twoKeyProtocol.TwoKeyParticipationMiningPool.getUserPendingSignature(user);
            expect(signatureOnContract).to.be.equal(signature);
        }).timeout(timeout);

        it('should withdraw tokens from mainchain', async() => {
            const {web3, address} = web3Switcher.renata();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_RENATA);

            let amountInProgressOfWithdrawal = await twoKeyProtocol.TwoKeyParticipationMiningPool.getHowMuchUserHaveInProgressOfWithdrawal(from);

            let txHash = await twoKeyProtocol.TwoKeyParticipationMiningPool.withdrawTokensWithSignature(
                signature,
                parseFloat(twoKeyProtocol.Utils.toWei(amountInProgressOfWithdrawal,'ether').toString()),
                from
            );

            // Wait until receipt is taken
            await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        }).timeout(timeout);

        it('should check accounting on mainchain after withdrawal is finished', async() => {
            let user = usersInEpoch[2];
            // Check if signature is existing
            let isSignatureExistingOnMainchain = await promisify(twoKeyProtocol.twoKeyParticipationMiningPool.isExistingSignature,[signature]);

            // Amount in progress of withdrawal on sidechain
            let amountInProgressOfWithdrawal = await twoKeyProtocol.TwoKeyParticipationMiningPool.getHowMuchUserHaveInProgressOfWithdrawal(user);


            let amountUserWithdrawnUsingSignature = await promisify(twoKeyProtocol.twoKeyParticipationMiningPool.getAmountUserWithdrawnUsingSignature,[
                user,
                signature
            ]);

            expect(isSignatureExistingOnMainchain).to.be.equal(true);
            expect(parseFloat(twoKeyProtocol.Utils.fromWei(amountUserWithdrawnUsingSignature,'ether').toString()))
                .to.be.equal(amountInProgressOfWithdrawal);
        }).timeout(timeout);

        it('maintainer should mark that user finished withdrawal on mainchain, and clear his sig', async() => {

            const {web3, address} = web3Switcher.buyer();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_BUYER);

            let user = usersInEpoch[2];

            let txHash = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.markUserFinishedWithdrawalFromMainchainWithSignature,[
                user,
                signature,
                {
                    from: twoKeyProtocol.plasmaAddress
                }
            ]);

            await new Promise(resolve => setTimeout(resolve, 2000));


            let signatureOnContract = await twoKeyProtocol.TwoKeyParticipationMiningPool.getUserPendingSignature(user);
            expect(signatureOnContract).to.be.equal('0x');
        }).timeout(timeout);

        it('should check that signature for this user is marked as used and withdrawn', async() => {
            let user = usersInEpoch[2];

            let isSignatureUsed = await twoKeyProtocol.TwoKeyParticipationMiningPool.getIfSignatureUsedOnMainchainForWithdrawal(user,signature);
            expect(isSignatureUsed).to.be.equal(true);
        }).timeout(timeout);

        it('should check that amount pending withdrawal is 0', async() => {
            let user = usersInEpoch[2];

            let amountInProgressOfWithdrawal = await twoKeyProtocol.TwoKeyParticipationMiningPool.getHowMuchUserHaveInProgressOfWithdrawal(user);
            expect(amountInProgressOfWithdrawal).to.be.equal(0);
        }).timeout(timeout);

    }
);
