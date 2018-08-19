require('truffle-test-utils').init();

const TwoKeyEventSource = artifacts.require("TwoKeyEventSource");
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");

contract('Event Source', async (accounts) => {
    it('emits events', async () => {
        let eventSource = await TwoKeyEventSource.new("0x0");

        let result = await eventSource.created(accounts[1], accounts[2]);

        assert.web3Event(result, {
		  event: 'Created',
		  args: {
		    _campaign: accounts[1],
		    _owner: accounts[2],
		  }
		}, 'The event is not emitted');

    });

    it('Should not have permission to emit', async() => {
    	let eventSource = await TwoKeyEventSource.new("0x0");

    	let canEmit = await eventSource.checkCanEmit("0x0");
    	assert.equal(canEmit, false, 'should fail if no');
	});


    it('Should try an error while trying to emit an event', async() => {
        let eventSource = await TwoKeyEventSource.new("0x0");

    })
});
