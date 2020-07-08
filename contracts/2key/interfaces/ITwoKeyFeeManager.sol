pragma solidity ^0.4.24;

contract ITwoKeyFeeManager {
    function payDebtWhenConvertingOrWithdrawingProceeds(address _plasmaAddress, uint _debtPaying) public payable;
    function getDebtForUser(address _userPlasma) public view returns (uint);
    function payDebtWithDAI(address _plasmaAddress, uint _totalDebt, uint _debtPaid) public;
    function payDebtWith2Key(address _beneficiaryPublic, address _plasmaAddress, uint _amountOf2keyForRewards) public;
    function payDebtWith2KeyV2(
        address _beneficiaryPublic,
        address _plasmaAddress,
        uint _amountOf2keyForRewards,
        address _twoKeyEconomy,
        address _twoKeyAdmin
    ) public;
    function setRegistrationFeeForUser(address _plasmaAddress, uint _registrationFee) public;
    function addDebtForUser(address _plasmaAddress, uint _debtAmount, string _debtType) public;
    function withdrawEtherCollected() public returns (uint);
    function withdraw2KEYCollected() public returns (uint);
    function withdrawDAICollected(address _dai) public returns (uint);
}
