pragma solidity ^0.4.24;

/**
 * @notice Contract to store important enumerators
 * @author Nikola Madjarevic
 */
contract TwoKeyConversionAndConverterStates {
    enum ConversionState {PENDING_APPROVAL, APPROVED, EXECUTED, REJECTED, CANCELLED_BY_CONVERTER}
    enum ConverterState {NOT_EXISTING, PENDING_APPROVAL, APPROVED, REJECTED}
}
