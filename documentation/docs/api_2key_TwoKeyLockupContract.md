---
id: 2key_TwoKeyLockupContract
title: TwoKeyLockupContract
---

<div class="contract-doc"><div class="contract"><h2 class="contract-header"><span class="contract-kind">contract</span> TwoKeyLockupContract</h2><div class="source">Source: <a href="git+https://github.com/2keynet/web3-alpha/blob/v0.0.3/contracts/2key/TwoKeyLockupContract.sol" target="_blank">2key/TwoKeyLockupContract.sol</a></div></div><div class="index"><h2>Index</h2><ul><li><a href="2key_TwoKeyLockupContract.html#cancelCampaignAndGetBackTokens">cancelCampaignAndGetBackTokens</a></li><li><a href="2key_TwoKeyLockupContract.html#changeTokenDistributionDate">changeTokenDistributionDate</a></li><li><a href="2key_TwoKeyLockupContract.html#">fallback</a></li><li><a href="2key_TwoKeyLockupContract.html#getLockupSummary">getLockupSummary</a></li><li><a href="2key_TwoKeyLockupContract.html#onlyContractor">onlyContractor</a></li><li><a href="2key_TwoKeyLockupContract.html#onlyConverter">onlyConverter</a></li><li><a href="2key_TwoKeyLockupContract.html#onlyTwoKeyConversionHandler">onlyTwoKeyConversionHandler</a></li><li><a href="2key_TwoKeyLockupContract.html#withdrawTokens">withdrawTokens</a></li></ul></div><div class="reference"><h2>Reference</h2><div class="modifiers"><h3>Modifiers</h3><ul><li><div class="item modifier"><span id="onlyContractor" class="anchor-marker"></span><h4 class="name">onlyContractor</h4><div class="body"><code class="signature">modifier <strong>onlyContractor</strong><span>() </span></code><hr/></div></div></li><li><div class="item modifier"><span id="onlyConverter" class="anchor-marker"></span><h4 class="name">onlyConverter</h4><div class="body"><code class="signature">modifier <strong>onlyConverter</strong><span>() </span></code><hr/></div></div></li><li><div class="item modifier"><span id="onlyTwoKeyConversionHandler" class="anchor-marker"></span><h4 class="name">onlyTwoKeyConversionHandler</h4><div class="body"><code class="signature">modifier <strong>onlyTwoKeyConversionHandler</strong><span>() </span></code><hr/></div></div></li></ul></div><div class="functions"><h3>Functions</h3><ul><li><div class="item function"><span id="cancelCampaignAndGetBackTokens" class="anchor-marker"></span><h4 class="name">cancelCampaignAndGetBackTokens</h4><div class="body"><code class="signature">function <strong>cancelCampaignAndGetBackTokens</strong><span>(address _assetContractERC20) </span><span>public </span></code><hr/><div class="description"><p>This function can only be called by conversion handler and that&#x27;s when contractor want to cancel his campaign.</p></div><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_TwoKeyLockupContract.html#onlyTwoKeyConversionHandler">onlyTwoKeyConversionHandler </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_assetContractERC20</code> - is the asset contract address</div></dd></dl></div></div></li><li><div class="item function"><span id="changeTokenDistributionDate" class="anchor-marker"></span><h4 class="name">changeTokenDistributionDate</h4><div class="body"><code class="signature">function <strong>changeTokenDistributionDate</strong><span>(uint _newDate) </span><span>public </span></code><hr/><div class="description"><p>Only contractor can issue calls to this method, and token distribution date can be changed only once, Function to change token distribution date.</p></div><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_TwoKeyLockupContract.html#onlyContractor">onlyContractor </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_newDate</code> - is new token distribution date we&#x27;d like to set</div></dd></dl></div></div></li><li><div class="item function"><span id="fallback" class="anchor-marker"></span><h4 class="name">fallback</h4><div class="body"><code class="signature">function <strong></strong><span>(uint _bonusTokensVestingStartShiftInDaysFromDistributionDate, uint _bonusTokensVestingMonths, uint _tokenDistributionDate, uint _maxDistributionDateShiftInDays, uint _baseTokens, uint _bonusTokens, uint _conversionId, address _converter, address _contractor, address _acquisitionCampaignERC20Address, address _assetContractERC20, address _twoKeyEventSource) </span><span>public </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_bonusTokensVestingStartShiftInDaysFromDistributionDate</code> - uint</div><div><code>_bonusTokensVestingMonths</code> - uint</div><div><code>_tokenDistributionDate</code> - uint</div><div><code>_maxDistributionDateShiftInDays</code> - uint</div><div><code>_baseTokens</code> - uint</div><div><code>_bonusTokens</code> - uint</div><div><code>_conversionId</code> - uint</div><div><code>_converter</code> - address</div><div><code>_contractor</code> - address</div><div><code>_acquisitionCampaignERC20Address</code> - address</div><div><code>_assetContractERC20</code> - address</div><div><code>_twoKeyEventSource</code> - address</div></dd></dl></div></div></li><li><div class="item function"><span id="getLockupSummary" class="anchor-marker"></span><h4 class="name">getLockupSummary</h4><div class="body"><code class="signature">function <strong>getLockupSummary</strong><span>() </span><span>public </span><span>view </span><span>returns  (uint, uint, uint, uint, uint[], bool[]) </span></code><hr/><dl><dt><span class="label-return">Returns:</span></dt><dd>uint</dd><dd>uint</dd><dd>uint</dd><dd>uint</dd><dd>uint[]</dd><dd>bool[]</dd></dl></div></div></li><li><div class="item function"><span id="withdrawTokens" class="anchor-marker"></span><h4 class="name">withdrawTokens</h4><div class="body"><code class="signature">function <strong>withdrawTokens</strong><span>(uint part) </span><span>public </span><span>returns  (bool) </span></code><hr/><div class="description"><p>Function where converter can withdraw his funds.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>part</code> - uint</div></dd><dt><span class="label-return">Returns:</span></dt><dd>true is if transfer was successful, otherwise will revert onlyConverter</dd></dl></div></div></li></ul></div></div></div>