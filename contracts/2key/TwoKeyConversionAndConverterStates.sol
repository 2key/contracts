pragma solidity ^0.4.24;

contract TwoKeyConversionAndConverterStates {
    enum ConversionState {PENDING_APPROVAL, APPROVED, EXECUTED, REJECTED, CANCELLED_BY_CONVERTER}
    enum ConverterState {NOT_EXISTING, PENDING_APPROVAL, APPROVED, REJECTED}
}
