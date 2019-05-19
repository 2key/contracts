pragma solidity ^0.4.24;

import "./TokenPool.sol";
import "../interfaces/ITwoKeyRegistry.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TwoKeyCommunityTokenPool is TokenPool {

    address public twoKeyRegistry;
    uint public constant totalAmount2keys = 200000000;
    uint public constant annualTransferAmountLimit = totalAmount2keys / 10;

    uint startingDate;

    struct AnnualReport {
        uint startingDate;
        uint transferedThisYear;
    }

    mapping(uint => AnnualReport) public yearToAnnualReport;

    uint256 [] annualTransfers;

    function setInitialParams(
        address _twoKeyAdmin,
        address _erc20Address,
        address [] _maintainers,
        address _twoKeyRegistry
    )
    external
    {
        require(initialized == false);
        setInitialParameters(_twoKeyAdmin, _erc20Address, _maintainers);
        twoKeyRegistry = _twoKeyRegistry;
        startingDate = block.timestamp;
        for(uint i=1;i<=10;i++) {
            yearToAnnualReport[i] = AnnualReport({startingDate: startingDate + i*(1 years),transferedThisYear: 0});
        }
        initialized = true;
    }

    /**
     * @notice Function to validate if the user is properly registered in TwoKeyRegistry
     */
    function validateRegistrationOfReceiver(
        address _receiver
    )
    internal
    view
    returns (bool)
    {
        return ITwoKeyRegistry(twoKeyRegistry).checkIfUserExists(_receiver);
    }

    /**
     * @notice Function which does transfer with special requirements with annual limit
     * @param _receiver is the receiver of the tokens
     * @param _amount is the amount of tokens sent
     * @dev Only TwoKeyAdmin contract can issue this call
     */
    function transferTokensToAddress(
        address _receiver,
        uint _amount
    )
    public
    onlyTwoKeyAdmin
    {
        require(validateRegistrationOfReceiver(_receiver) == true);
        require(_amount > 0);

        uint year = checkInWhichYearIsTheTransfer();
        require(year >= 1 && year <= 10);

        AnnualReport memory report = yearToAnnualReport[year];

        require(report.transferedThisYear + _amount <= annualTransferAmountLimit);
        super.transferTokens(_receiver,_amount);
        report.transferedThisYear = report.transferedThisYear + _amount;

        yearToAnnualReport[year] = report;
    }

    function checkInWhichYearIsTheTransfer()
    public
    view
    returns (uint)
    {
        if(block.timestamp > startingDate && block.timestamp < startingDate + 1 years) {
            return 1;
        } else {
            uint counter = 1;
            uint start = startingDate + 1 years; //means we're checking for the second year
            while(block.timestamp > start || counter == 10) {
                start = start + 1 years;
                counter ++;
            }
            return counter;
        }
    }

}
