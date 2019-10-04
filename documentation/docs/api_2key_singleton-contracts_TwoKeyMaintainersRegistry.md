---
id: 2key_singleton-contracts_TwoKeyMaintainersRegistry
title: TwoKeyMaintainersRegistry
---

<div class="contract-doc"><div class="contract"><h2 class="contract-header"><span class="contract-kind">contract</span> TwoKeyMaintainersRegistry</h2><p class="base-contracts"><span>is</span> <a href="2key_upgradability_Upgradeable.html">Upgradeable</a></p><div class="source">Source: <a href="https://github.com/2keynet/web3-alpha/blob/v0.0.3/contracts/2key/singleton-contracts/TwoKeyMaintainersRegistry.sol" target="_blank">contracts/2key/singleton-contracts/TwoKeyMaintainersRegistry.sol</a></div><div class="author">Author: Nikola Madjarevic</div></div><div class="index"><h2>Index</h2><ul><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#addMaintainer">addMaintainer</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#addMaintainers">addMaintainers</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#decrementNumberOfActiveMaintainers">decrementNumberOfActiveMaintainers</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#getAddressFromTwoKeySingletonRegistry">getAddressFromTwoKeySingletonRegistry</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#getAllMaintainers">getAllMaintainers</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#getMaintainerPerId">getMaintainerPerId</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#getNumberOfActiveMaintainers">getNumberOfActiveMaintainers</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#getNumberOfMaintainers">getNumberOfMaintainers</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#incrementNumberOfActiveMaintainers">incrementNumberOfActiveMaintainers</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#incrementNumberOfMaintainers">incrementNumberOfMaintainers</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#isMaintainer">isMaintainer</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#onlyMaintainer">onlyMaintainer</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#onlyTwoKeyAdmin">onlyTwoKeyAdmin</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#removeMaintainer">removeMaintainer</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#removeMaintainers">removeMaintainers</a></li><li><a href="2key_singleton-contracts_TwoKeyMaintainersRegistry.html#setInitialParams">setInitialParams</a></li></ul></div><div class="reference"><h2>Reference</h2><div class="functions"><h3>Functions</h3><ul><li><div class="item function"><span id="addMaintainer" class="anchor-marker"></span><h4 class="name">addMaintainer</h4><div class="body"><code class="signature">function <strong>addMaintainer</strong><span>(address _maintainer) </span><span>internal </span></code><hr/><div class="description"><p>Function which will add maintainer.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_maintainer</code> - is the address of new maintainer we&#x27;re adding</div></dd></dl></div></div></li><li><div class="item function"><span id="addMaintainers" class="anchor-marker"></span><h4 class="name">addMaintainers</h4><div class="body"><code class="signature">function <strong>addMaintainers</strong><span>(address[] _maintainers) </span><span>public </span></code><hr/><div class="description"><p>Only twoKeyAdmin contract is eligible to mutate state of maintainers, Function which can add new maintainers, in general it&#x27;s array because this supports adding multiple addresses in 1 trnx.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_maintainers</code> - is the array of maintainer addresses</div></dd></dl></div></div></li><li><div class="item function"><span id="decrementNumberOfActiveMaintainers" class="anchor-marker"></span><h4 class="name">decrementNumberOfActiveMaintainers</h4><div class="body"><code class="signature">function <strong>decrementNumberOfActiveMaintainers</strong><span>() </span><span>internal </span></code><hr/></div></div></li><li><div class="item function"><span id="getAddressFromTwoKeySingletonRegistry" class="anchor-marker"></span><h4 class="name">getAddressFromTwoKeySingletonRegistry</h4><div class="body"><code class="signature">function <strong>getAddressFromTwoKeySingletonRegistry</strong><span>(string contractName) </span><span>internal </span><span>view </span><span>returns  (address) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>contractName</code> - string</div></dd><dt><span class="label-return">Returns:</span></dt><dd>address</dd></dl></div></div></li><li><div class="item function"><span id="getAllMaintainers" class="anchor-marker"></span><h4 class="name">getAllMaintainers</h4><div class="body"><code class="signature">function <strong>getAllMaintainers</strong><span>() </span><span>public </span><span>view </span><span>returns  (address[]) </span></code><hr/><div class="description"><p>Function to get all maintainers set DURING CAMPAIGN CREATION.</p></div><dl><dt><span class="label-return">Returns:</span></dt><dd>address[]</dd></dl></div></div></li><li><div class="item function"><span id="getMaintainerPerId" class="anchor-marker"></span><h4 class="name">getMaintainerPerId</h4><div class="body"><code class="signature">function <strong>getMaintainerPerId</strong><span>(uint _id) </span><span>public </span><span>view </span><span>returns  (address) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_id</code> - uint</div></dd><dt><span class="label-return">Returns:</span></dt><dd>address</dd></dl></div></div></li><li><div class="item function"><span id="getNumberOfActiveMaintainers" class="anchor-marker"></span><h4 class="name">getNumberOfActiveMaintainers</h4><div class="body"><code class="signature">function <strong>getNumberOfActiveMaintainers</strong><span>() </span><span>public </span><span>view </span><span>returns  (uint) </span></code><hr/><dl><dt><span class="label-return">Returns:</span></dt><dd>uint</dd></dl></div></div></li><li><div class="item function"><span id="getNumberOfMaintainers" class="anchor-marker"></span><h4 class="name">getNumberOfMaintainers</h4><div class="body"><code class="signature">function <strong>getNumberOfMaintainers</strong><span>() </span><span>public </span><span>view </span><span>returns  (uint) </span></code><hr/><dl><dt><span class="label-return">Returns:</span></dt><dd>uint</dd></dl></div></div></li><li><div class="item function"><span id="incrementNumberOfActiveMaintainers" class="anchor-marker"></span><h4 class="name">incrementNumberOfActiveMaintainers</h4><div class="body"><code class="signature">function <strong>incrementNumberOfActiveMaintainers</strong><span>() </span><span>internal </span></code><hr/></div></div></li><li><div class="item function"><span id="incrementNumberOfMaintainers" class="anchor-marker"></span><h4 class="name">incrementNumberOfMaintainers</h4><div class="body"><code class="signature">function <strong>incrementNumberOfMaintainers</strong><span>() </span><span>internal </span></code><hr/></div></div></li><li><div class="item function"><span id="isMaintainer" class="anchor-marker"></span><h4 class="name">isMaintainer</h4><div class="body"><code class="signature">function <strong>isMaintainer</strong><span>(address _address) </span><span>internal </span><span>view </span><span>returns  (bool) </span></code><hr/><div class="description"><p>Function to check if address is maintainer.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_address</code> - is the address we&#x27;re checking if it&#x27;s maintainer or not</div></dd><dt><span class="label-return">Returns:</span></dt><dd>bool</dd></dl></div></div></li><li><div class="item function"><span id="onlyMaintainer" class="anchor-marker"></span><h4 class="name">onlyMaintainer</h4><div class="body"><code class="signature">function <strong>onlyMaintainer</strong><span>(address _sender) </span><span>public </span><span>view </span><span>returns  (bool) </span></code><hr/><div class="description"><p>Function which will determine if address is maintainer.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_sender</code> - address</div></dd><dt><span class="label-return">Returns:</span></dt><dd>bool</dd></dl></div></div></li><li><div class="item function"><span id="onlyTwoKeyAdmin" class="anchor-marker"></span><h4 class="name">onlyTwoKeyAdmin</h4><div class="body"><code class="signature">function <strong>onlyTwoKeyAdmin</strong><span>(address sender) </span><span>public </span><span>view </span><span>returns  (bool) </span></code><hr/><div class="description"><p>Modifier to restrict calling the method to anyone but twoKeyAdmin.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>sender</code> - address</div></dd><dt><span class="label-return">Returns:</span></dt><dd>bool</dd></dl></div></div></li><li><div class="item function"><span id="removeMaintainer" class="anchor-marker"></span><h4 class="name">removeMaintainer</h4><div class="body"><code class="signature">function <strong>removeMaintainer</strong><span>(address _maintainer) </span><span>internal </span></code><hr/><div class="description"><p>Function which will remove maintainer.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_maintainer</code> - is the address of the maintainer we&#x27;re removing</div></dd></dl></div></div></li><li><div class="item function"><span id="removeMaintainers" class="anchor-marker"></span><h4 class="name">removeMaintainers</h4><div class="body"><code class="signature">function <strong>removeMaintainers</strong><span>(address[] _maintainers) </span><span>public </span></code><hr/><div class="description"><p>Only twoKeyAdmin contract is eligible to mutate state of maintainers, Function which can remove some maintainers, in general it&#x27;s array because this supports adding multiple addresses in 1 trnx.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_maintainers</code> - is the array of maintainer addresses</div></dd></dl></div></div></li><li><div class="item function"><span id="setInitialParams" class="anchor-marker"></span><h4 class="name">setInitialParams</h4><div class="body"><code class="signature">function <strong>setInitialParams</strong><span>(address _twoKeySingletonRegistry, address _proxyStorage, address[] _maintainers) </span><span>public </span></code><hr/><div class="description"><p>Function which can be called only once, and is used as replacement for a constructor.</p></div><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_twoKeySingletonRegistry</code> - is the address of TWO_KEY_SINGLETON_REGISTRY contract</div><div><code>_proxyStorage</code> - is the address of proxy of storage contract</div><div><code>_maintainers</code> - is the array of initial maintainers we&#x27;ll kick off contract with</div></dd></dl></div></div></li></ul></div></div></div>