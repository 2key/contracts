# Convention for commenting and writing solidity code

- Solidity contracts can have a special form of comments that form the basis of the Ethereum Natural Specification Format

- Documentation is inserted above the function following the doxygen notation of either one or multiple lines starting with /// or a multiline comment starting with /** and ending with */.

### Tags
```
@title - A title that should describe the contract	[Context: Contract / Interface]
@author - The name of the author of the contract	[Context: Contract / Interface / Function]
@notice - Explain to a user what a function does	[Context: Contract / Interface / Function]
@dev - Explain to a developer any extra details	    [Context: Contract / Interface / Function]
@param - Documents a parameter just like in doxygen (must be followed by parameter name) [Context: Function] 
(for example if param is called '_param1' it need to have same name in annotation) --> @param _param1
@return - Documents the return type of a contract's function	[Context: Function]
```

I'd suggest to make every contract in separated .sol file, not to have few contracts in same .sol file,
because it's much easier to find and organize code structure.

###Example
```
pragma solidity ^0.4.19;

/// @title A simulator for Bug Bunny, the most famous Rabbit
/// @author Warned Bros
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implement without side effects
contract BugsBunny {
    /// @author Bob Clampett
    /// @notice Determine if Bugs will accept `(_food)` to eat
    /// @dev String comparison may be inefficient
    /// @param _food The name of a food to evaluate (English)
    /// @return true if Bugs will eat it, false otherwise
    function doesEat(string _food) external pure returns (bool) {
        return keccak256(_food) == keccak256("carrot");
    }
}
```