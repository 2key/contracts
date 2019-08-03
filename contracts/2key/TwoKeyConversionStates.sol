pragma solidity ^0.4.24;

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyConversionStates {
    enum ConversionState {PENDING_APPROVAL, APPROVED, EXECUTED, REJECTED, CANCELLED_BY_CONVERTER}
}
