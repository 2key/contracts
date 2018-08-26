pragma solidity ^0.4.24;

import "../2key/RBACWithAdmin.sol";
import "../openzeppelin-solidity/contracts/math/SafeMath.sol";

contract IComposableAssetFactory is RBACWithAdmin{

    modifier isOngoing() {
        _;
    }

    constructor(uint256 _openingTime, uint256 _closingTime) RBACWithAdmin() public{

    }
    function addFungibleAsset(uint256 _tokenID, address _assetContract, uint256 _amount) public returns (bool);

    function addNonFungibleAsset(uint256 _tokenID, address _assetContract, uint256 _index) public returns (bool);

    function moveFungibleAsset(address _to, uint256 _tokenID, address _assetContract, uint256 _amount) internal returns (bool);

    function moveNonFungibleAsset(address _to, uint256 _tokenID, uint256 _assetTokenID) internal returns (bool);

    function transferFungibleAsset(address _to, uint256 _tokenID, address _assetContract, uint256 _amount)  public returns (bool);

    function transferNonFungibleAsset(address _to, uint256 _tokenID, address _assetContract, uint256 _assetTokenID) internal returns (bool);

    function expireFungible(address _to, uint256 _tokenID, address _assetContract, uint256 _amount) public returns (bool);

    function expireNonFungible(address _to, uint256 _tokenID, address _assetContract, uint256 _assetTokenID) public returns (bool);
}
