---
id: 2key_TwoKeyAirdropCampaign
title: TwoKeyAirdropCampaign
---

<div class="contract-doc"><div class="contract"><h2 class="contract-header"><span class="contract-kind">contract</span> TwoKeyAirdropCampaign</h2><p class="base-contracts"><span>is</span> <a href="2key_TwoKeyConversionStates.html">TwoKeyConversionStates</a></p><p class="description">Contract for the airdrop campaigns.</p><div class="source">Source: <a href="https://github.com/2keynet/web3-alpha/blob/v0.0.3/contracts/2key/TwoKeyAirdropCampaign.sol" target="_blank">contracts/2key/TwoKeyAirdropCampaign.sol</a></div><div class="author">Author: Nikola Madjarevic Created at 12/20/18</div></div><div class="index"><h2>Index</h2><ul><li><a href="2key_TwoKeyAirdropCampaign.html#activateCampaign">activateCampaign</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#approveConversion">approveConversion</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#convert">convert</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#convertConversionStateToBytes">convertConversionStateToBytes</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#converterWithdraw">converterWithdraw</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#">fallback</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#getContractInformations">getContractInformations</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#getConversion">getConversion</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#getConverterBalance">getConverterBalance</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#getReferrerBalanceAndTotalEarnings">getReferrerBalanceAndTotalEarnings</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#isOngoing">isOngoing</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#onlyContractor">onlyContractor</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#onlyIfActivated">onlyIfActivated</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#onlyIfMaxNumberOfConversionsNotReached">onlyIfMaxNumberOfConversionsNotReached</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#referrerWithdraw">referrerWithdraw</a></li><li><a href="2key_TwoKeyAirdropCampaign.html#rejectConversion">rejectConversion</a></li></ul></div><div class="reference"><h2>Reference</h2><div class="modifiers"><h3>Modifiers</h3><ul><li><div class="item modifier"><span id="isOngoing" class="anchor-marker"></span><h4 class="name">isOngoing</h4><div class="body"><code class="signature">modifier <strong>isOngoing</strong><span>() </span></code><hr/></div></div></li><li><div class="item modifier"><span id="onlyContractor" class="anchor-marker"></span><h4 class="name">onlyContractor</h4><div class="body"><code class="signature">modifier <strong>onlyContractor</strong><span>() </span></code><hr/></div></div></li><li><div class="item modifier"><span id="onlyIfActivated" class="anchor-marker"></span><h4 class="name">onlyIfActivated</h4><div class="body"><code class="signature">modifier <strong>onlyIfActivated</strong><span>() </span></code><hr/></div></div></li><li><div class="item modifier"><span id="onlyIfMaxNumberOfConversionsNotReached" class="anchor-marker"></span><h4 class="name">onlyIfMaxNumberOfConversionsNotReached</h4><div class="body"><code class="signature">modifier <strong>onlyIfMaxNumberOfConversionsNotReached</strong><span>() </span></code><hr/></div></div></li></ul></div><div class="functions"><h3>Functions</h3><ul><li><div class="item function"><span id="activateCampaign" class="anchor-marker"></span><h4 class="name">activateCampaign</h4><div class="body"><code class="signature">function <strong>activateCampaign</strong><span>() </span><span>external </span></code><hr/><div class="description"><p>Only contractor can activate campaign We&#x27;re supposing that he has already sent his tokens to the contract, and also submitted (staked) 2key fee, Function to activate campaign.</p></div><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_TwoKeyAirdropCampaign.html#onlyContractor">onlyContractor </a></dd></dl></div></div></li><li><div class="item function"><span id="approveConversion" class="anchor-marker"></span><h4 class="name">approveConversion</h4><div class="body"><code class="signature">function <strong>approveConversion</strong><span>(uint conversionId) </span><span>external </span></code><hr/><div class="description"><p>This function can be called only by contractor, Function to approve conversion.</p></div><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_TwoKeyAirdropCampaign.html#onlyContractor">onlyContractor </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>conversionId</code> - is the id of the conversion (position in the array of conversions)</div></dd></dl></div></div></li><li><div class="item function"><span id="convert" class="anchor-marker"></span><h4 class="name">convert</h4><div class="body"><code class="signature">function <strong>convert</strong><span>(bytes signature) </span><span>external </span></code><hr/><div class="description"><p>This function will revert if the maxNumberOfConversions is reached, Function which will be executed to create conversion.</p></div><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_TwoKeyAirdropCampaign.html#onlyIfActivated">onlyIfActivated </a><a href="2key_TwoKeyAirdropCampaign.html#onlyIfMaxNumberOfConversionsNotReached">onlyIfMaxNumberOfConversionsNotReached </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>signature</code> - bytes</div></dd></dl></div></div></li><li><div class="item function"><span id="convertConversionStateToBytes" class="anchor-marker"></span><h4 class="name">convertConversionStateToBytes</h4><div class="body"><code class="signature">function <strong>convertConversionStateToBytes</strong><span>(ConversionState state) </span><span>internal </span><span>pure </span><span>returns  (bytes32) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>state</code> - ConversionState</div></dd><dt><span class="label-return">Returns:</span></dt><dd>bytes32</dd></dl></div></div></li><li><div class="item function"><span id="converterWithdraw" class="anchor-marker"></span><h4 class="name">converterWithdraw</h4><div class="body"><code class="signature">function <strong>converterWithdraw</strong><span>() </span><span>external </span></code><hr/><div class="description"><p>Once the conversion is approved, means that converter has done the required action and he can withdraw tokens.</p></div></div></div></li><li><div class="item function"><span id="fallback" class="anchor-marker"></span><h4 class="name">fallback</h4><div class="body"><code class="signature">function <strong></strong><span>(uint _inventory, address _erc20ContractAddress, uint _campaignStartTime, uint _campaignEndTime, uint _numberOfTokensPerConverterAndReferralChain) </span><span>public </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_inventory</code> - uint</div><div><code>_erc20ContractAddress</code> - address</div><div><code>_campaignStartTime</code> - uint</div><div><code>_campaignEndTime</code> - uint</div><div><code>_numberOfTokensPerConverterAndReferralChain</code> - uint</div></dd></dl></div></div></li><li><div class="item function"><span id="getContractInformations" class="anchor-marker"></span><h4 class="name">getContractInformations</h4><div class="body"><code class="signature">function <strong>getContractInformations</strong><span>() </span><span>external </span><span>view </span><span>returns  (bytes) </span></code><hr/><div class="description"><p>Function to return dynamic and static contract data, visible to everyone.</p></div><dl><dt><span class="label-return">Returns:</span></dt><dd>encoded data</dd></dl></div></div></li><li><div class="item function"><span id="getConversion" class="anchor-marker"></span><h4 class="name">getConversion</h4><div class="body"><code class="signature">function <strong>getConversion</strong><span>(uint conversionId) </span><span>external </span><span>view </span><span>returns  (address, uint, bytes32) </span></code><hr/><div class="description"><p>Function to get conversion object.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>conversionId</code> - is the id of the conversion</div></dd><dt><span class="label-return">Returns:</span></dt><dd>tuple containing respectively converter address, conversionTime, and state of the conversion</dd></dl></div></div></li><li><div class="item function"><span id="getConverterBalance" class="anchor-marker"></span><h4 class="name">getConverterBalance</h4><div class="body"><code class="signature">function <strong>getConverterBalance</strong><span>(address _converter) </span><span>external </span><span>view </span><span>returns  (uint) </span></code><hr/><div class="description"><p>Only converter by himself or contractor can see balance for the converter, Function to determine the balance of converter.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_converter</code> - address is the only argument we need</div></dd><dt><span class="label-return">Returns:</span></dt><dd>uint</dd></dl></div></div></li><li><div class="item function"><span id="getReferrerBalanceAndTotalEarnings" class="anchor-marker"></span><h4 class="name">getReferrerBalanceAndTotalEarnings</h4><div class="body"><code class="signature">function <strong>getReferrerBalanceAndTotalEarnings</strong><span>(address _referrer) </span><span>external </span><span>view </span><span>returns  (uint, uint) </span></code><hr/><div class="description"><p>Only referrer by himself or contractor can see the balance of the referrer, Function returns the total available balance of the referrer and his total earnings for this campaign.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_referrer</code> - is the address of the referrer we&#x27;re checking balance for</div></dd><dt><span class="label-return">Returns:</span></dt><dd>uint</dd><dd>uint</dd></dl></div></div></li><li><div class="item function"><span id="referrerWithdraw" class="anchor-marker"></span><h4 class="name">referrerWithdraw</h4><div class="body"><code class="signature">function <strong>referrerWithdraw</strong><span>() </span><span>external </span></code><hr/><div class="description"><p>If referrer doesn&#x27;t have any balance this will revert, Function to withdraw erc20 tokens for the referrer.</p></div></div></div></li><li><div class="item function"><span id="rejectConversion" class="anchor-marker"></span><h4 class="name">rejectConversion</h4><div class="body"><code class="signature">function <strong>rejectConversion</strong><span>(uint conversionId) </span><span>external </span></code><hr/><div class="description"><p>This function can be called only by contractor, Function to reject conversion.</p></div><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_TwoKeyAirdropCampaign.html#onlyContractor">onlyContractor </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>conversionId</code> - is the id of the conversion</div></dd></dl></div></div></li></ul></div></div></div>