import '../constants/polifils';
import availableUsers, {userIds} from "../constants/availableUsers";
import usersActions from "./reusable/usersActions";
import {campaignUserActions} from "./constants/constants";
import TestStorage from "../helperClasses/TestStorage";
import {campaignTypes, incentiveModels} from "../constants/smallConstants";
import {ICreateCampaign} from "../../src/donation/interfaces";
import createDonationCampaign from "./helpers/createDonationCampaign";
import checkDonationCampaign from "./reusable/checkDonationCampaign";

const contributionSize = 1;

const  campaignData: ICreateCampaign = {
  moderator: undefined,
  invoiceToken: {
    tokenName: 'NikolaToken',
    tokenSymbol: 'NTKN',
  },
  maxReferralRewardPercent: 20,
  campaignStartTime: 0,
  campaignEndTime: 9884748832,
  minDonationAmount: 1,
  maxDonationAmount: 10,
  campaignGoal: 10000000000000000000000000000000,
  referrerQuota: 5,
  isKYCRequired: false,
  shouldConvertToRefer: false,
  acceptsFiat: false,
  incentiveModel: incentiveModels.manual,
  currency: 'ETH',
  endCampaignOnceGoalReached: false,
  expiryConversionInHours: 0,
};

const campaignUsers = {
  gmail: {
    cut: 50,
    percentCut: 0.5,
  },
  test4: {
    cut: 20,
    percentCut: 0.20,
  },
  renata: {
    cut: 20,
    percentCut: 0.2,
  },
};

describe(
  'exampleDonationTest',
  () => {
    const storage = new TestStorage(userIds.aydnep, campaignTypes.donation, campaignData.isKYCRequired);

    before(function () {
      this.timeout(60000);
      return createDonationCampaign(campaignData, storage);
    });

    checkDonationCampaign(campaignData, storage);


    usersActions(
      {
        userKey: userIds.guest,
        secondaryUserKey: storage.contractorKey,
        actions: [campaignUserActions.visit],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.gmail,
        secondaryUserKey: storage.contractorKey,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.join,
        ],
        campaignData,
        storage,
        cut: campaignUsers.gmail.cut,
      }
    );

    usersActions(
      {
        userKey: userIds.test4,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.join,
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        cut: campaignUsers.test4.cut,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: userIds.renata,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.checkConverterSpent,
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        cut: campaignUsers.test4.cut,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: userIds.uport,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.joinAndConvert,
          campaignUserActions.cancelConvert,
        ],
        campaignData,
        storage,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: storage.contractorKey,
        secondaryUserKey: userIds.test4,
        actions: [
          campaignUserActions.checkPendingConverters,
          campaignUserActions.approveConverter,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.test4,
        actions: [
          campaignUserActions.executeConversion,
        ],
        campaignData,
        storage,
        cut: campaignUsers.test4.cut,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: storage.contractorKey,
        secondaryUserKey: userIds.renata,
        actions: [
          campaignUserActions.rejectConverter,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.renata,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.checkRestrictedConvert,
        ],
        contribution: contributionSize,
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: storage.contractorKey,
        actions: [
          campaignUserActions.hedgingEth,
        ],
        campaignData,
        storage,
      }
    );
    usersActions(
      {
        userKey: storage.contractorKey,
        secondaryUserKey: userIds.test4,
        actions: [
          campaignUserActions.checkERC20Balance,
        ],
        campaignData,
        storage,
      }
    );

/*


        it('should get conversion object', async() => {
            printTestNumber();

            let conversionId = 0;
            let conversion: IConversion = await twoKeyProtocol.DonationCampaign.getConversion(campaignAddress, conversionId, from);
            console.log(conversion);
            expect(conversion.conversionState).to.be.equal("EXECUTED");
        }).timeout(60000);

        it('should print referrers', async() => {
            printTestNumber();
            let influencers = await twoKeyProtocol.DonationCampaign.getRefferrersToConverter(campaignAddress,  env.TEST4_ADDRESS, from);
            console.log(influencers);
        }).timeout(60000);

        it('should get referrer earnings', async() => {
            printTestNumber();
            let refPlasma = generatePlasmaFromMnemonic(env.MNEMONIC_GMAIL).address;
            console.log('Referrer plasma address: ' + refPlasma);
            let referrerBalance = await twoKeyProtocol.DonationCampaign.getReferrerBalance(campaignAddress, refPlasma, from);
            expect(referrerBalance).to.be.equal(250);
        }).timeout(60000);

        it('should get reserved amount for referrers', async() => {
            printTestNumber();
            let referrerReservedAmount = await twoKeyProtocol.DonationCampaign.getReservedAmount2keyForRewards(campaignAddress);
            expect(referrerReservedAmount).to.be.equal(250);
        }).timeout(60000);

        it('should get number of influencers to converter', async() => {
            let numberOfInfluencers = await twoKeyProtocol.DonationCampaign.getNumberOfInfluencersForConverter(campaignAddress, env.TEST4_ADDRESS);
            expect(numberOfInfluencers).to.be.equal(1);
        }).timeout(60000);

        it('should check is address contractor', async() => {
            printTestNumber();
            const {web3, address} = web3Switcher.deployer();
            from = address;
            twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_DEPLOYER));
            let isAddressContractor = await twoKeyProtocol.DonationCampaign.isAddressContractor(campaignAddress, from);
            expect(isAddressContractor).to.be.equal(true);
        }).timeout(60000);

        it('should get contractor balance and total earnings', async() => {
            printTestNumber();
            const {web3, address} = web3Switcher.deployer();
            from = address;
            twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_DEPLOYER));
            let earnings = await twoKeyProtocol.DonationCampaign.getContractorBalanceAndTotalProceeds(campaignAddress, from);
            console.log(earnings);
        }).timeout(60000);

        it('should test if address is joined', async() => {
            printTestNumber();
            let isJoined = await twoKeyProtocol.DonationCampaign.isAddressJoined(campaignAddress,from);
            console.log(isJoined);
        }).timeout(60000);

        it('should get how much user have spent', async() => {
            printTestNumber();
            let amountSpent = await twoKeyProtocol.DonationCampaign.getAmountConverterSpent(campaignAddress, env.TEST4_ADDRESS);
            expect(amountSpent).to.be.equal(1);
        }).timeout(60000);

        it('should show how much user can donate', async() => {
            printTestNumber();
            let leftToDonate = await twoKeyProtocol.DonationCampaign.howMuchUserCanContribute(campaignAddress, env.TEST4_ADDRESS, from);
            console.log(leftToDonate);
            let expectedValue = conversionAmountEth;
            if(currency == 'USD') {
                expectedValue = conversionAmountEth * 100;
            }
            expect(leftToDonate).to.be.equal(maxDonationAmount-expectedValue);
        }).timeout(60000);

        it('should show address statistic', async() => {
            printTestNumber();
            const {web3, address} = web3Switcher.test4();
            from = address;
            twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_TEST4));
            let stats = await twoKeyProtocol.DonationCampaign.getAddressStatistic(campaignAddress,env.TEST4_ADDRESS, '0x0000000000000000000000000000000000000000',{from});
            console.log(stats);
        }).timeout(60000);

        it('should show stats for referrer', async() => {
            printTestNumber();
            const {web3, address} = web3Switcher.gmail();
            from = address;
            twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_GMAIL));

            let signature = await twoKeyProtocol.PlasmaEvents.signReferrerToGetRewards();
            let stats = await twoKeyProtocol.DonationCampaign.getReferrerBalanceAndTotalEarningsAndNumberOfConversions(campaignAddress, signature);
            console.log(stats);
        }).timeout(60000);

        it('should get balance of TwoKeyEconomy tokens on DonationCampaign', async() => {
            printTestNumber();
            let balance = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyEconomy, campaignAddress);
            console.log('ERC20 TwoKeyEconomy balance on this contract is : ' + balance);
        }).timeout(60000);

        it('should get stats for the contract from upgradable exchange', async() => {
            printTestNumber();
            let stats = await twoKeyProtocol.UpgradableExchange.getStatusForTheContract(campaignAddress, from);
            console.log(stats);
        }).timeout(60000);

        it('referrer should withdraw his earnings', async() => {
            printTestNumber();
            let txHash = await twoKeyProtocol.DonationCampaign.moderatorAndReferrerWithdraw(campaignAddress, false, from);
            await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        }).timeout(60000);


        usersActions(
          {
            userKey: storage.contractorKey,
            actions: [
              campaignUserActions.hedgingEth,
            ],
            campaignData,
            storage,
          }
        );

        usersActions(
          {
            userKey: userIds.test4,
            actions: [
              campaignUserActions.checkCampaignSummary,
              campaignUserActions.checkModeratorEarnings,
              campaignUserActions.withdrawTokens,
            ],
            campaignData,
            storage,
          }
        );

        usersActions(
          {
            userKey: storage.contractorKey,
            secondaryUserKey: userIds.gmail,
            actions: [
              campaignUserActions.checkWithdrawableBalance,
            ],
            campaignData,
            storage,
          }
        );
        usersActions(
          {
            userKey: storage.contractorKey,
            actions: [
              campaignUserActions.contractorWithdraw,
            ],
            campaignData,
            storage,
          }
        );
        usersActions(
          {
            userKey: userIds.gmail,
            actions: [
              campaignUserActions.checkStatistic,
            ],
            campaignData,
            storage,
          }
        );
        usersActions(
          {
            userKey: userIds.renata,
            actions: [
              campaignUserActions.moderatorAndReferrerWithdraw,
              campaignUserActions.checkTotalEarnings,
              campaignUserActions.checkERC20Balance,
            ],
            campaignData,
            storage,
          }
        );
        usersActions(
          {
            userKey: storage.contractorKey,
            actions: [
              campaignUserActions.checkConverterMetric,
            ],
            campaignData,
            storage,
          }
        );
        usersActions(
          {
            userKey: userIds.gmail2,
            actions: [
              campaignUserActions.createOffline,
            ],
            campaignData,
            storage,
            contribution: 50,
          }
        );
        usersActions(
          {
            userKey: storage.contractorKey,
            actions: [
              campaignUserActions.contractorExecuteConversion,
            ],
            campaignData,
            storage,
          }
        );
        */
  },
);
