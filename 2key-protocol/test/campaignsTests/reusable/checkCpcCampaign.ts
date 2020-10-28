import availableUsers, {userIds} from "../../constants/availableUsers";
import {expect} from "chai";
import ICreateCPCTest from "../../typings/ICreateCPCTest";
import {expectEqualNumbers} from "../../helpers/numberHelpers";
import {promisify} from "../../../src/utils/promisify";

const TIMEOUT_LENGTH = 60000;

export default function checkCpcCampaign(campaignParams: ICreateCPCTest, storage, maintainerKey: string) {
  const userKey = storage.contractorKey;

  if (
    !campaignParams.etherForRewards
    && !campaignParams.targetClicks
    && campaignParams.bountyPerConversionUSD
  ) {
    throw new Error('Required CPC campaign params missing');
  }

  it('should get contractor plasma and public address', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const contractorAddress = await protocol.CPCCampaign.getContractorAddresses(campaignAddress);
    expect(contractorAddress).to.be.equal(protocol.plasmaAddress);
  }).timeout(TIMEOUT_LENGTH);

  it('should check if address is contractor', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const isContractor = await protocol.CPCCampaign.isAddressContractor(campaignAddress, protocol.plasmaAddress);
    expect(isContractor).to.be.equal(true);
  }).timeout(TIMEOUT_LENGTH);

  it('should get private meta hash', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);

    let privateMeta = await protocol.CPCCampaign.getPrivateMetaHash(campaignAddress, protocol.plasmaAddress);
    expect(privateMeta.campaignPublicLinkKey).to.be.equal(user.link.link);
  }).timeout(TIMEOUT_LENGTH);


  it('should directly transfer tokens to campaign', async () => {
    const {protocol, web3: {address}, web3} = availableUsers[userKey];
    const {protocol: withBalanceProtocol, web3: {address: addressWithBalance}} = availableUsers[userIds.aydnep]; //user with 2keys
    const {campaignAddress, campaign} = storage;

    const inventoryBefore = await protocol.CPCCampaign.getInitialBountyAmount(campaignAddress);
    let usdTotalAmount = campaignParams.bountyPerConversionUSD * campaignParams.targetClicks + 0.1;

    if(Math.random() > 0.5) {
      // Random case budgeting with 2KEY

      let amountOfTokens = await protocol.CPCCampaign.getRequiredBudget2KEY('USD', protocol.Utils.toWei(usdTotalAmount,'ether').toString());

      let amountOfTokensWei = protocol.Utils.toWei(amountOfTokens,'ether').toString();


      await withBalanceProtocol.Utils.getTransactionReceiptMined(
          await withBalanceProtocol.transfer2KEYTokens(address, amountOfTokensWei, addressWithBalance)
      );

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.ERC20.erc20ApproveAddress(
          protocol.twoKeyEconomy.address,
          protocol.twoKeyBudgetCampaignsPaymentsHandler.address,
          amountOfTokensWei,
          address
        )
      );

      let receipt = await protocol.Utils.getTransactionReceiptMined(
          await protocol.CPCCampaign.addDirectly2KEYAsInventory(campaignAddress, amountOfTokensWei, protocol.Utils.toWei(campaignParams.bountyPerConversionUSD).toString(), address)
      );

      console.log('Add directly 2KEY gas used: ', receipt.gasUsed);

      const inventoryAfter = await protocol.CPCCampaign.getInitialBountyAmount(campaignAddress);

      expectEqualNumbers(
        (inventoryAfter - inventoryBefore),
          amountOfTokens,
      );
    } else {
        // Ranadom case budgeting with DAI/TUSD/BUSD/...
        let amountOfTokensRequired = await protocol.TwoKeyExchangeContract.getFiatToStableQuotes(
            parseFloat(protocol.Utils.toWei(usdTotalAmount,'ether').toString()),
            'USD',
            ['DAI']
          );

        let amountOfTokensWei = await protocol.Utils.toWei(amountOfTokensRequired.DAI,'ether').toString();
        let daiAddress = await protocol.SingletonRegistry.getNonUpgradableContractAddress('DAI');

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.ERC20.erc20ApproveAddress(
            daiAddress,
            protocol.twoKeyBudgetCampaignsPaymentsHandler.address,
            amountOfTokensWei,
            address
          )
        );

        let txHash;

        let receipt = await protocol.Utils.getTransactionReceiptMined(
            txHash = await protocol.CPCCampaign.addInventoryWithStableCoin(
                campaignAddress,
                amountOfTokensWei,
                protocol.Utils.toWei(campaignParams.bountyPerConversionUSD).toString(),
                daiAddress,
                address
            )
        );
      console.log('Gas used: ', receipt.gasUsed);
        const inventoryAfter = await protocol.CPCCampaign.getInitialBountyAmount(campaignAddress);
    }
  });

  it('should set that plasma contract is valid from maintainer', async () => {
    const {protocol} = availableUsers[maintainerKey];
    const {campaignAddress} = storage;

    let c = await protocol.CPCCampaign._getPlasmaCampaignInstance(campaignAddress);


    let initialParams = await protocol.CPCCampaign.getInitialParamsForCampaign(campaignAddress);
    console.log(initialParams);

    // This should set total bounty, initial rate and validate campaign
    await promisify(c.setInitialParamsAndValidateCampaign,[
        protocol.Utils.toWei(initialParams.initialBountyForCampaign,'ether'),
        protocol.Utils.toWei(initialParams.initialRate2KEYUSD,'ether'),
        protocol.Utils.toWei(initialParams.bountyPerConversion2KEY,'ether'),
        initialParams.isBudgetedDirectlyWith2KEY,
        {from: protocol.plasmaAddress}
    ])

    await new Promise(resolve => setTimeout(resolve, 4000));

    // Check is plasma contract valid
    const isPlasmaValid = await protocol.CPCCampaign.checkIsPlasmaContractValid(campaignAddress);
    expect(isPlasmaValid).to.be.eq(true);

    // Check if bounty is set properly
    const bounty = await protocol.CPCCampaign.getTotalBountyAndBountyPerConversion(campaignAddress);
    expect(bounty.totalBounty).to.be.equal(initialParams.initialBountyForCampaign);
    expect(bounty.bountyPerConversion).to.be.equal(initialParams.bountyPerConversion2KEY);
  }).timeout(TIMEOUT_LENGTH);


  it('should get campaign from IPFS', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const campaignMeta = await protocol.CPCCampaign.getPublicMeta(campaignAddress, protocol.plasmaAddress);
    expect(campaignMeta.meta.url).to.be.equal(campaignParams.url);
  }).timeout(TIMEOUT_LENGTH);

  it('should get public link key of contractor', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const pkl = await protocol.CPCCampaign.getPublicLinkKey(campaignAddress, protocol.plasmaAddress);
    expect(pkl.length).to.be.greaterThan(0);
  }).timeout(TIMEOUT_LENGTH);
}
