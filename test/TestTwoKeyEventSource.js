require('truffle-test-utils').init();

const TwoKeyEventSource = artifacts.require("TwoKeyEventSource");

contract('Event Source', async (accounts) => {
    it('emits events', async () => {
        let eventSource = await TwoKeyEventSource.new();

        let result = await eventSource.created(accounts[1], accounts[2]);

        assert.web3Event(result, {
		  event: 'Created',
		  args: {
		    _campaign: accounts[1],
		    _owner: accounts[2],
		  }
		}, 'The event is not emitted');

    });
});
