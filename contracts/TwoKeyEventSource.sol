pragma solidity ^0.4.24;

contract TwoKeyEventSource {

    event Created(address indexed _owner, address _campaign); // TODO Yoram changed
    event Joined(address indexed _to, address _campaign);  // TODO Yoram Joined event is different
	event Escrow(address indexed _campaign, address indexed _escrow, address indexed _sender, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount);
	event Rewarded(address indexed _campaign, address indexed _to, uint256 _amount);
    event Fulfilled(address indexed _campaign, address indexed _converter, uint256 indexed _tokenID, address _childContractID, uint256 _indexOrAmount);
    event Cancelled(address indexed _campaign, address indexed _converter, uint256 indexed _tokenID, address _childContractID, uint256 _indexOrAmount);

    function created(// address _campaign, // TODO Yoram are you OK with this?
		address _owner) public {
		address _campaign = msg.sender;
		// TODO Yoram: check if we can get the code of c and check if the has exists in a list allowed codes
		// TODO Yoram: only the owner of TwoKeyReg is allowed to edit the list of allowed codes
    	emit Created(_owner, _campaign);
    }

    function joined(// address _campaign, // TODO Yoram are you OK with this?
//		address _from,  // TODO Yoram are you OK with this?
		address _to) public {
		address _campaign = msg.sender;
    	emit Joined(_to, _campaign); // TODO Yoram Joined event is different
    }

    function escrow(address _campaign, address _escrow, address _sender, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount) public {
    	emit Escrow(_campaign, _escrow, _sender, _tokenID, _childContractID, _indexOrAmount);
    }

    function rewarded(address _campaign, address _to, uint256 _amount) public {
    	emit Rewarded(_campaign, _to, _amount);
	}

	function fulfilled(address  _campaign, address _converter, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount) public {
		emit Fulfilled(_campaign, _converter, _tokenID, _childContractID, _indexOrAmount);
	}

	function cancelled(address  _campaign, address _converter, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount) public {
		emit Cancelled(_campaign, _converter, _tokenID, _childContractID, _indexOrAmount);
	}

}