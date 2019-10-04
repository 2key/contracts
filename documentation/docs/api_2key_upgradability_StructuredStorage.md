---
id: 2key_upgradability_StructuredStorage
title: StructuredStorage
---

<div class="contract-doc"><div class="contract"><h2 class="contract-header"><span class="contract-kind">contract</span> StructuredStorage</h2><p class="base-contracts"><span>is</span> <a href="2key_upgradability_Upgradeable.html">Upgradeable</a></p><div class="source">Source: <a href="https://github.com/2keynet/web3-alpha/blob/v0.0.3/contracts/2key/upgradability/StructuredStorage.sol" target="_blank">contracts/2key/upgradability/StructuredStorage.sol</a></div></div><div class="index"><h2>Index</h2><ul><li><a href="2key_upgradability_StructuredStorage.html#deleteAddress">deleteAddress</a></li><li><a href="2key_upgradability_StructuredStorage.html#deleteBool">deleteBool</a></li><li><a href="2key_upgradability_StructuredStorage.html#deleteBytes">deleteBytes</a></li><li><a href="2key_upgradability_StructuredStorage.html#deleteBytes32">deleteBytes32</a></li><li><a href="2key_upgradability_StructuredStorage.html#deleteInt">deleteInt</a></li><li><a href="2key_upgradability_StructuredStorage.html#deleteString">deleteString</a></li><li><a href="2key_upgradability_StructuredStorage.html#deleteUint">deleteUint</a></li><li><a href="2key_upgradability_StructuredStorage.html#getAddress">getAddress</a></li><li><a href="2key_upgradability_StructuredStorage.html#getAddressArray">getAddressArray</a></li><li><a href="2key_upgradability_StructuredStorage.html#getBool">getBool</a></li><li><a href="2key_upgradability_StructuredStorage.html#getBoolArray">getBoolArray</a></li><li><a href="2key_upgradability_StructuredStorage.html#getBytes">getBytes</a></li><li><a href="2key_upgradability_StructuredStorage.html#getBytes32">getBytes32</a></li><li><a href="2key_upgradability_StructuredStorage.html#getBytes32Array">getBytes32Array</a></li><li><a href="2key_upgradability_StructuredStorage.html#getInt">getInt</a></li><li><a href="2key_upgradability_StructuredStorage.html#getIntArray">getIntArray</a></li><li><a href="2key_upgradability_StructuredStorage.html#getString">getString</a></li><li><a href="2key_upgradability_StructuredStorage.html#getUint">getUint</a></li><li><a href="2key_upgradability_StructuredStorage.html#getUintArray">getUintArray</a></li><li><a href="2key_upgradability_StructuredStorage.html#onlyDeployer">onlyDeployer</a></li><li><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract</a></li><li><a href="2key_upgradability_StructuredStorage.html#setAddress">setAddress</a></li><li><a href="2key_upgradability_StructuredStorage.html#setAddressArray">setAddressArray</a></li><li><a href="2key_upgradability_StructuredStorage.html#setBool">setBool</a></li><li><a href="2key_upgradability_StructuredStorage.html#setBoolArray">setBoolArray</a></li><li><a href="2key_upgradability_StructuredStorage.html#setBytes">setBytes</a></li><li><a href="2key_upgradability_StructuredStorage.html#setBytes32">setBytes32</a></li><li><a href="2key_upgradability_StructuredStorage.html#setBytes32Array">setBytes32Array</a></li><li><a href="2key_upgradability_StructuredStorage.html#setInt">setInt</a></li><li><a href="2key_upgradability_StructuredStorage.html#setIntArray">setIntArray</a></li><li><a href="2key_upgradability_StructuredStorage.html#setProxyLogicContract">setProxyLogicContract</a></li><li><a href="2key_upgradability_StructuredStorage.html#setProxyLogicContractAndDeployer">setProxyLogicContractAndDeployer</a></li><li><a href="2key_upgradability_StructuredStorage.html#setString">setString</a></li><li><a href="2key_upgradability_StructuredStorage.html#setUint">setUint</a></li><li><a href="2key_upgradability_StructuredStorage.html#setUintArray">setUintArray</a></li></ul></div><div class="reference"><h2>Reference</h2><div class="modifiers"><h3>Modifiers</h3><ul><li><div class="item modifier"><span id="onlyDeployer" class="anchor-marker"></span><h4 class="name">onlyDeployer</h4><div class="body"><code class="signature">modifier <strong>onlyDeployer</strong><span>() </span></code><hr/></div></div></li><li><div class="item modifier"><span id="onlyProxyLogicContract" class="anchor-marker"></span><h4 class="name">onlyProxyLogicContract</h4><div class="body"><code class="signature">modifier <strong>onlyProxyLogicContract</strong><span>() </span></code><hr/></div></div></li></ul></div><div class="functions"><h3>Functions</h3><ul><li><div class="item function"><span id="deleteAddress" class="anchor-marker"></span><h4 class="name">deleteAddress</h4><div class="body"><code class="signature">function <strong>deleteAddress</strong><span>(bytes32 _key) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd></dl></div></div></li><li><div class="item function"><span id="deleteBool" class="anchor-marker"></span><h4 class="name">deleteBool</h4><div class="body"><code class="signature">function <strong>deleteBool</strong><span>(bytes32 _key) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd></dl></div></div></li><li><div class="item function"><span id="deleteBytes" class="anchor-marker"></span><h4 class="name">deleteBytes</h4><div class="body"><code class="signature">function <strong>deleteBytes</strong><span>(bytes32 _key) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd></dl></div></div></li><li><div class="item function"><span id="deleteBytes32" class="anchor-marker"></span><h4 class="name">deleteBytes32</h4><div class="body"><code class="signature">function <strong>deleteBytes32</strong><span>(bytes32 _key) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd></dl></div></div></li><li><div class="item function"><span id="deleteInt" class="anchor-marker"></span><h4 class="name">deleteInt</h4><div class="body"><code class="signature">function <strong>deleteInt</strong><span>(bytes32 _key) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd></dl></div></div></li><li><div class="item function"><span id="deleteString" class="anchor-marker"></span><h4 class="name">deleteString</h4><div class="body"><code class="signature">function <strong>deleteString</strong><span>(bytes32 _key) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd></dl></div></div></li><li><div class="item function"><span id="deleteUint" class="anchor-marker"></span><h4 class="name">deleteUint</h4><div class="body"><code class="signature">function <strong>deleteUint</strong><span>(bytes32 _key) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd></dl></div></div></li><li><div class="item function"><span id="getAddress" class="anchor-marker"></span><h4 class="name">getAddress</h4><div class="body"><code class="signature">function <strong>getAddress</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (address) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>address</dd></dl></div></div></li><li><div class="item function"><span id="getAddressArray" class="anchor-marker"></span><h4 class="name">getAddressArray</h4><div class="body"><code class="signature">function <strong>getAddressArray</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (address[]) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>address[]</dd></dl></div></div></li><li><div class="item function"><span id="getBool" class="anchor-marker"></span><h4 class="name">getBool</h4><div class="body"><code class="signature">function <strong>getBool</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (bool) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>bool</dd></dl></div></div></li><li><div class="item function"><span id="getBoolArray" class="anchor-marker"></span><h4 class="name">getBoolArray</h4><div class="body"><code class="signature">function <strong>getBoolArray</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (bool[]) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>bool[]</dd></dl></div></div></li><li><div class="item function"><span id="getBytes" class="anchor-marker"></span><h4 class="name">getBytes</h4><div class="body"><code class="signature">function <strong>getBytes</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (bytes) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>bytes</dd></dl></div></div></li><li><div class="item function"><span id="getBytes32" class="anchor-marker"></span><h4 class="name">getBytes32</h4><div class="body"><code class="signature">function <strong>getBytes32</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (bytes32) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>bytes32</dd></dl></div></div></li><li><div class="item function"><span id="getBytes32Array" class="anchor-marker"></span><h4 class="name">getBytes32Array</h4><div class="body"><code class="signature">function <strong>getBytes32Array</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (bytes32[]) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>bytes32[]</dd></dl></div></div></li><li><div class="item function"><span id="getInt" class="anchor-marker"></span><h4 class="name">getInt</h4><div class="body"><code class="signature">function <strong>getInt</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (int) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>int</dd></dl></div></div></li><li><div class="item function"><span id="getIntArray" class="anchor-marker"></span><h4 class="name">getIntArray</h4><div class="body"><code class="signature">function <strong>getIntArray</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (int[]) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>int[]</dd></dl></div></div></li><li><div class="item function"><span id="getString" class="anchor-marker"></span><h4 class="name">getString</h4><div class="body"><code class="signature">function <strong>getString</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (string) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>string</dd></dl></div></div></li><li><div class="item function"><span id="getUint" class="anchor-marker"></span><h4 class="name">getUint</h4><div class="body"><code class="signature">function <strong>getUint</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (uint) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>uint</dd></dl></div></div></li><li><div class="item function"><span id="getUintArray" class="anchor-marker"></span><h4 class="name">getUintArray</h4><div class="body"><code class="signature">function <strong>getUintArray</strong><span>(bytes32 _key) </span><span>external </span><span>view </span><span>returns  (uint[]) </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div></dd><dt><span class="label-return">Returns:</span></dt><dd>uint[]</dd></dl></div></div></li><li><div class="item function"><span id="setAddress" class="anchor-marker"></span><h4 class="name">setAddress</h4><div class="body"><code class="signature">function <strong>setAddress</strong><span>(bytes32 _key, address _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - address</div></dd></dl></div></div></li><li><div class="item function"><span id="setAddressArray" class="anchor-marker"></span><h4 class="name">setAddressArray</h4><div class="body"><code class="signature">function <strong>setAddressArray</strong><span>(bytes32 _key, address[] _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - address[]</div></dd></dl></div></div></li><li><div class="item function"><span id="setBool" class="anchor-marker"></span><h4 class="name">setBool</h4><div class="body"><code class="signature">function <strong>setBool</strong><span>(bytes32 _key, bool _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - bool</div></dd></dl></div></div></li><li><div class="item function"><span id="setBoolArray" class="anchor-marker"></span><h4 class="name">setBoolArray</h4><div class="body"><code class="signature">function <strong>setBoolArray</strong><span>(bytes32 _key, bool[] _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - bool[]</div></dd></dl></div></div></li><li><div class="item function"><span id="setBytes" class="anchor-marker"></span><h4 class="name">setBytes</h4><div class="body"><code class="signature">function <strong>setBytes</strong><span>(bytes32 _key, bytes _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - bytes</div></dd></dl></div></div></li><li><div class="item function"><span id="setBytes32" class="anchor-marker"></span><h4 class="name">setBytes32</h4><div class="body"><code class="signature">function <strong>setBytes32</strong><span>(bytes32 _key, bytes32 _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - bytes32</div></dd></dl></div></div></li><li><div class="item function"><span id="setBytes32Array" class="anchor-marker"></span><h4 class="name">setBytes32Array</h4><div class="body"><code class="signature">function <strong>setBytes32Array</strong><span>(bytes32 _key, bytes32[] _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - bytes32[]</div></dd></dl></div></div></li><li><div class="item function"><span id="setInt" class="anchor-marker"></span><h4 class="name">setInt</h4><div class="body"><code class="signature">function <strong>setInt</strong><span>(bytes32 _key, int _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - int</div></dd></dl></div></div></li><li><div class="item function"><span id="setIntArray" class="anchor-marker"></span><h4 class="name">setIntArray</h4><div class="body"><code class="signature">function <strong>setIntArray</strong><span>(bytes32 _key, int[] _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - int[]</div></dd></dl></div></div></li><li><div class="item function"><span id="setProxyLogicContract" class="anchor-marker"></span><h4 class="name">setProxyLogicContract</h4><div class="body"><code class="signature">function <strong>setProxyLogicContract</strong><span>(address _proxyLogicContract) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyDeployer">onlyDeployer </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_proxyLogicContract</code> - address</div></dd></dl></div></div></li><li><div class="item function"><span id="setProxyLogicContractAndDeployer" class="anchor-marker"></span><h4 class="name">setProxyLogicContractAndDeployer</h4><div class="body"><code class="signature">function <strong>setProxyLogicContractAndDeployer</strong><span>(address _proxyLogicContract, address deployer) </span><span>external </span></code><hr/><dl><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_proxyLogicContract</code> - address</div><div><code>deployer</code> - address</div></dd></dl></div></div></li><li><div class="item function"><span id="setString" class="anchor-marker"></span><h4 class="name">setString</h4><div class="body"><code class="signature">function <strong>setString</strong><span>(bytes32 _key, string _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - string</div></dd></dl></div></div></li><li><div class="item function"><span id="setUint" class="anchor-marker"></span><h4 class="name">setUint</h4><div class="body"><code class="signature">function <strong>setUint</strong><span>(bytes32 _key, uint _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - uint</div></dd></dl></div></div></li><li><div class="item function"><span id="setUintArray" class="anchor-marker"></span><h4 class="name">setUintArray</h4><div class="body"><code class="signature">function <strong>setUintArray</strong><span>(bytes32 _key, uint[] _value) </span><span>external </span></code><hr/><dl><dt><span class="label-modifiers">Modifiers:</span></dt><dd><a href="2key_upgradability_StructuredStorage.html#onlyProxyLogicContract">onlyProxyLogicContract </a></dd><dt><span class="label-parameters">Parameters:</span></dt><dd><div><code>_key</code> - bytes32</div><div><code>_value</code> - uint[]</div></dd></dl></div></div></li></ul></div></div></div>