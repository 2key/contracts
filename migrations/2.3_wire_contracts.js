const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyReg = artifacts.require('TwoKeyReg');

module.exports = function(deployer,networks,accounts) {
    EventSource.deployed().then(eventSource => {
        console.log("... Adding TwoKeyReg to EventSource");
        eventSource.addTwoKeyReg(TwoKeyReg.address);
        console.log("Added TwoKeyReg: " + TwoKeyReg.address + "  to EventSource : " + EventSource.address + "!")
    }).then(true);
}
