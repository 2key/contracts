pragma solidity ^0.4.24;

/**
 * @notice Contract to store important enumerators
 * @author Nikola Madjarevic
 */
contract TwoKeyConversionStates {
    enum ConversionState {PENDING_APPROVAL, APPROVED, EXECUTED, REJECTED, CANCELLED_BY_CONVERTER}

    function convertConversionStateToBytes(ConversionState state) internal pure returns (bytes32) {
        if(state == ConversionState.PENDING_APPROVAL) {
            return bytes32("PENDING_APPROVAL");
        } else if(state == ConversionState.APPROVED) {
            return bytes32("APPROVED");
        } else if(state == ConversionState.EXECUTED) {
            return bytes32("EXECUTED");
        } else if(state == ConversionState.REJECTED) {
            return bytes32("REJECTED");
        } else if(state == ConversionState.CANCELLED_BY_CONVERTER) {
            return bytes32("CANCELLED_BY_CONVERTER");
        } else {
            return bytes32(0);
        }
    }
}
