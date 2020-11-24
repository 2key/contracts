import {expect} from 'chai';
import 'mocha';
import web3Switcher from "../../helpers/web3Switcher";
import {TwoKeyProtocol} from "../../../src";
import getTwoKeyProtocol from "../../helpers/twoKeyProtocol";
import {promisify} from "../../../src/utils/promisify";


import Sign from "../../../src/sign";

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');


const timeout = 60000;
const ONE_MONTH_UNIX = 30 * 24 * 60 * 60 + 60; // 30 days = 30 * 24 hrs = 30 * 24 * 60 minutes = 30 * 24 * 60 * 60 seconds + 1 minute

describe(
    'TwoKeyParticipationMiningRewards test',
    () => {
        let from: string;
        let twoKeyProtocol: TwoKeyProtocol;
        let signature: string;
        let epochId; // Epoch id
        let usersInEpoch; // Pick 6 users to submit in the epoch
        let userRewards; // Generate random rewards for the users
        let numberOfProposals;
        let transactionBytecode;
        before(
            function () {
                this.timeout(timeout);

                const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.deployer();

                from = address;
                twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);
            }
        );


        it('should create a proposal on plasma congress to declare epochs', async() => {
            transactionBytecode =
                "0xbc21c011000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000009000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000000000000000000068155a43676e00000";
            const destination = twoKeyProtocol.twoKeyPlasmaParticipationRewards._address;

            let txHash: string = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.newProposal, [
                destination,
                0,
                "Declare epochs",
                transactionBytecode,
                {
                    from: twoKeyProtocol.plasmaAddress
                }
            ]);

            const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash,{web3: twoKeyProtocol.plasmaWeb3});
            const status = receipt && receipt.status;
            expect(status).to.be.equal('0x1');
        }).timeout(timeout);

        it('should member 1. vote for supporting proposal', async() => {
            numberOfProposals = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.numProposals,[]);
            numberOfProposals = parseInt(numberOfProposals,10) - 1;

            let txHash: string = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.vote,[
                numberOfProposals,
                true,
                "I support declaring this epochs",
                {
                    from: twoKeyProtocol.plasmaAddress,
                }
            ]);

            const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash,{web3: twoKeyProtocol.plasmaWeb3});
            const status = receipt && receipt.status;
            expect(status).to.be.equal('0x1');
        }).timeout(timeout);

        it('should member 2. vote for supporting proposal', async() => {
            const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.aydnep();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);

            let txHash: string = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.vote,[
                numberOfProposals,
                true,
                "I support declaring this epochs",
                {
                    from: twoKeyProtocol.plasmaAddress
                }
            ]);

            const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash,{web3: twoKeyProtocol.plasmaWeb3});
            const status = receipt && receipt.status;
            expect(status).to.be.equal('0x1');
        }).timeout(timeout);

        it('should member 3 vote for supporting proposal', async() => {

            const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.gmail();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);

            let txHash: string = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.vote,[
                numberOfProposals,
                true,
                "I support declaring this epochs",
                {
                    from: twoKeyProtocol.plasmaAddress
                }
            ]);

            const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash,{web3: twoKeyProtocol.plasmaWeb3});
            const status = receipt && receipt.status;
            expect(status).to.be.equal('0x1');
        }).timeout(timeout);

        it('should execute proposal', async() => {
            let txHash: string = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.executeProposal,[
                numberOfProposals,
                transactionBytecode,
                {
                    from: twoKeyProtocol.plasmaAddress,
                    gas: 7000000
                }
            ]);

            const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash,{web3: twoKeyProtocol.plasmaWeb3});
            const status = receipt && receipt.status;
            expect(status).to.be.equal('0x1');
        }).timeout(timeout);

        it('should set users and rewards', async() => {
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
        }).timeout(timeout);

        it('should register participation mining epoch', async () => {

            const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.buyer();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);

            // Get latest epoch id
            epochId = parseInt(await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getLatestFinalizedEpochId, []), 10) + 1;

            let numberOfUsers = usersInEpoch.length;

            // First step is to register epoch
            await twoKeyProtocol.Utils.getTransactionReceiptMined(
                await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.registerEpoch,
                    [
                        epochId,
                        numberOfUsers,
                        {
                            from: twoKeyProtocol.plasmaAddress
                        }
                    ]),
                {web3: twoKeyProtocol.plasmaWeb3}
            );

            let epochInProgress = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getEpochIdInProgress,[]);
            expect(parseInt(epochInProgress)).to.be.equal(epochId);
        }).timeout(timeout);

        it('should submit users and their rewards in the epoch', async() => {
            let txHash = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.assignRewardsInActiveMiningEpoch,
                [
                    epochId,
                    usersInEpoch,
                    userRewards,
                    {
                        from: twoKeyProtocol.plasmaAddress,
                        gas: 7000000
                    }
                ]);

            await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash,{web3: twoKeyProtocol.plasmaWeb3});
        }).timeout(timeout)

        it('should get total users in epoch', async() => {
            let totalUsersInEpoch = await twoKeyProtocol.TwoKeyParticipationMiningPool.getTotalUsersInEpoch(epochId);
            expect(totalUsersInEpoch).to.be.equal(usersInEpoch.length);
        }).timeout(timeout);

        it('should finalize epoch', async() => {
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

        it('should check that after epoch is finalized latest epoch id is the one submitted', async() => {
            let latestEpochId = parseInt(await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getLatestFinalizedEpochId,[]),10);
            expect(latestEpochId).to.be.equal(epochId);
        }).timeout(timeout);

        it('should check that epoch in progress is now equal 0', async() => {
            let epochInProgress = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getEpochIdInProgress,[]);
            expect(parseInt(epochInProgress,10)).to.be.equal(0);
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
                let userPendingEpochIds = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getPendingEpochsForUser, [usersInEpoch[i]]);
                // Convert big numbers to uint
                userPendingEpochIds = userPendingEpochIds.map((element) => {
                    return parseInt(element, 10)
                });
                // Expect that the last pending epoch id is the on submitted now.
                expect(userPendingEpochIds[userPendingEpochIds.length - 1]).to.be.equal(epochId);
            }
        }).timeout(timeout);

        it('should sign user rewards and user address by signatory address', async () => {

            const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.nikola();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);


            let user = usersInEpoch[2];
            let pending = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getUserTotalPendingAmount, [user]);

            // Convert to 64 places hex
            let pendingHex = twoKeyProtocol.Utils.toHex(pending);
            pendingHex = pendingHex.slice(2);

            // hex(64)
            while (pendingHex.length < 64) {
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

            // Change maintainer because the one signed can't send this message
            const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.buyer();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);

            let user = usersInEpoch[2];
            let pending = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getUserTotalPendingAmount,[user]);

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
                    gas: 7000000
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
            pending = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getUserTotalPendingAmount,[user]);

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


        it('maintainer should set monthly allowance and date from which is counting starting', async() => {
            // Change maintainer because the one signed can't send this message
            const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.buyer();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);


            let dateStartingCountingMonths = await promisify(twoKeyProtocol.twoKeyParticipationMiningPool.getDateStartingCountingMonths,[]);

            if(dateStartingCountingMonths.toString() === '0') {
                // Get timestamp of latest block
                let blockNumber = await twoKeyProtocol.Utils.getLatestBlock();
                let blockTimestamp = await twoKeyProtocol.Utils.getBlockTimestamp(blockNumber);

                await twoKeyProtocol.Utils.getTransactionReceiptMined(
                  await promisify(twoKeyProtocol.twoKeyParticipationMiningPool.setWithdrawalParameters,[
                      blockTimestamp,
                      {
                          from
                      }
                  ])
                );

                dateStartingCountingMonths = await promisify(twoKeyProtocol.twoKeyParticipationMiningPool.getDateStartingCountingMonths,[]);
                expect(dateStartingCountingMonths.toString()).to.be.equal(blockTimestamp.toString());
            }

            // We need to assert that monthly transfer allowance is 1M
            let monthlyTransferAllowance = await promisify(
                twoKeyProtocol.twoKeyParticipationMiningPool.getMonthlyTransferAllowance,[]
            );

            monthlyTransferAllowance = parseFloat(
              twoKeyProtocol.Utils.fromWei(monthlyTransferAllowance,'ether').toString()
            );

            expect(monthlyTransferAllowance).to.be.equal(1000000);
        }).timeout(timeout);

        it('should check that monthly allowances are properly calculating on mainchain', async() => {
            let dateStartingCountingMonths = await promisify(twoKeyProtocol.twoKeyParticipationMiningPool.getDateStartingCountingMonths, []);
            dateStartingCountingMonths = parseFloat(dateStartingCountingMonths.toString());

            let monthlyTransferAllowance = await promisify(
                twoKeyProtocol.twoKeyParticipationMiningPool.getMonthlyTransferAllowance, []
            );

            monthlyTransferAllowance = parseFloat(
                twoKeyProtocol.Utils.fromWei(monthlyTransferAllowance, 'ether').toString()
            );

            let allowance = await twoKeyProtocol.TwoKeyParticipationMiningPool.getCurrentUnlockedAmountOfTokensForWithdrawal(dateStartingCountingMonths + ONE_MONTH_UNIX);
        }).timeout(timeout);

        it('should withdraw tokens from mainchain', async() => {
            const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.renata();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);

            let totalAmountOfTokensTransfered = await promisify(twoKeyProtocol.twoKeyParticipationMiningPool.getTotalAmountOfTokensTransfered, []);
            totalAmountOfTokensTransfered = parseFloat(twoKeyProtocol.Utils.fromWei(totalAmountOfTokensTransfered, 'ether').toString());

            let amountInProgressOfWithdrawal = await twoKeyProtocol.TwoKeyParticipationMiningPool.getHowMuchUserHaveInProgressOfWithdrawal(from);

            let txHash = await twoKeyProtocol.TwoKeyParticipationMiningPool.withdrawTokensWithSignature(
                signature,
                parseFloat(twoKeyProtocol.Utils.toWei(amountInProgressOfWithdrawal, 'ether').toString()),
                from
            );

            console.log(txHash);

            // Wait until receipt is taken
            let receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
            console.log('Gas required for withdrawal on mainchain is: ', receipt.gasUsed);

            let totalAmountOfTokensTransferedAfterWithdrawal = await promisify(twoKeyProtocol.twoKeyParticipationMiningPool.getTotalAmountOfTokensTransfered, []);
            totalAmountOfTokensTransferedAfterWithdrawal = parseFloat(twoKeyProtocol.Utils.fromWei(totalAmountOfTokensTransferedAfterWithdrawal, 'ether').toString());

            expect(totalAmountOfTokensTransfered + amountInProgressOfWithdrawal).to.be.equal(totalAmountOfTokensTransferedAfterWithdrawal);
        }).timeout(timeout);

        it('should check if signature is marked as it exists on mainchain', async() => {
            // Check if signature is existing
            let isSignatureExistingOnMainchain = await promisify(twoKeyProtocol.twoKeyParticipationMiningPool.isExistingSignature,[signature]);

            expect(isSignatureExistingOnMainchain).to.be.equal(true);
        }).timeout(timeout);

        it('should mark that user finished withdrawal on mainchain, and clear his sig, called by maintainer', async() => {
            const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.buyer();

            from = address;
            twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);

            let user = usersInEpoch[2];


            // Amount in progress of withdrawal on sidechain
            let amountInProgressOfWithdrawal = await twoKeyProtocol.TwoKeyParticipationMiningPool.getHowMuchUserHaveInProgressOfWithdrawal(user);

            let txHash = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.markUserFinishedWithdrawalFromMainchainWithSignature,[
                user,
                signature,
                {
                    from: twoKeyProtocol.plasmaAddress
                }
            ]);

            await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash,{web3: twoKeyProtocol.plasmaWeb3});

            let amountUserWithdrawnUsingSignature = await promisify(twoKeyProtocol.twoKeyPlasmaParticipationRewards.getAmountUserWithdrawnUsingSignature,[
                user,
                signature
            ]);

            // Amount in progress of withdrawal on sidechain
            let amountAfterWithdrawalInProgress = await twoKeyProtocol.TwoKeyParticipationMiningPool.getHowMuchUserHaveInProgressOfWithdrawal(user);

            let signatureOnContract = await twoKeyProtocol.TwoKeyParticipationMiningPool.getUserPendingSignature(user);

            expect(amountAfterWithdrawalInProgress.toString()).to.be.equal('0');
            expect(amountInProgressOfWithdrawal).to.be.equal(parseFloat(twoKeyProtocol.Utils.fromWei(amountUserWithdrawnUsingSignature,'ether').toString()))
            expect(signatureOnContract).to.be.equal('0x');
        }).timeout(timeout);


        it('should check that amount pending withdrawal is 0', async() => {
            let user = usersInEpoch[2];

            let amountInProgressOfWithdrawal = await twoKeyProtocol.TwoKeyParticipationMiningPool.getHowMuchUserHaveInProgressOfWithdrawal(user);
            expect(amountInProgressOfWithdrawal).to.be.equal(0);
        }).timeout(timeout);

    }
);
