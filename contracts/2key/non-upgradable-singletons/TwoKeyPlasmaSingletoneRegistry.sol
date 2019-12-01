pragma solidity ^0.4.24;

import "./TwoKeySingletonRegistryAbstract.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyPlasmaSingletoneRegistry is TwoKeySingletonRegistryAbstract {

    constructor()
    public
    {
        deployer = msg.sender;
        congress = "TwoKeyPlasmaCongress";
        maintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    }
}
