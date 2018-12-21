pragma solidity ^0.4.24;

contract TwoKeyConverterStates {
    enum ConverterState {NOT_EXISTING, PENDING_APPROVAL, APPROVED, REJECTED}

    /// @notice Function to convert converter state to it's bytes representation (Maybe we don't even need it)
    /// @param state is conversion state
    /// @return bytes32 (hex) representation of state
    function convertConverterStateToBytes(ConverterState state) internal pure returns (bytes32) {
        if(ConverterState.PENDING_APPROVAL == state) {
            return bytes32("PENDING_APPROVAL");
        }
        if(ConverterState.APPROVED == state) {
            return bytes32("APPROVED");
        }
        if(ConverterState.REJECTED == state) {
            return bytes32("REJECTED");
        }
    }
}
