pragma solidity ^0.4.24;

import "./ITwoKeySingletonUtils.sol";
import "../upgradability/Upgradeable.sol";

contract TwoKeySignatureValidator is Upgradeable, ITwoKeySingletonUtils {

    /**
     * TODO: Make 1 function per signature type which will validate either it is good or not
     * TODO: Here we don't need any kind of storage, so it can be literally used as a library

     */
}
