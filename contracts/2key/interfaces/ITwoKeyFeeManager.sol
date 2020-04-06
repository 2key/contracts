pragma solidity ^0.4.24;

contract ITwoKeyFeeManager {
    function payDebtWhenConvertingOrWithdrawingProceeds(address _plasmaAddress, uint _debtPaying) public payable;
    function getDebtForUser(address _userPlasma) public view returns (uint);
    function payDebtWithDAI(address _plasmaAddress, uint _totalDebt, uint _debtPaid) public;
    function payDebtWith2Key(address _beneficiaryPublic, address _plasmaAddress, uint _amountOf2keyForRewards) public;
    function setRegistrationFeeForUser(address _plasmaAddress, uint _registrationFee) public;
    function setReRegistrationFeeForUser(address _plasmaAddress, uint _reRegistrationFee) public;
    function withdrawEtherCollected() public;
}
