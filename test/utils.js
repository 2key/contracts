// source: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/test/helpers/increaseTime.js
module.exports.increaseTime = function increaseTime(duration) {
  const id = Date.now();

  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync(
      {
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [duration],
        id: id
      },
      err1 => {
        if (err1) return reject(err1);

        web3.currentProvider.sendAsync(
          {
            jsonrpc: "2.0",
            method: "evm_mine",
            id: id + 1
          },
          (err2, res) => {
            return err2 ? reject(err2) : resolve(res);
          }
        );
      }
    );
  });
};


// Returns the time of the last mined block in seconds
module.exports.latestTime = function() {
  return web3.eth.getBlock('latest').timestamp;
};

module.exports.duration = {
  seconds: function (val) { return val; },
  minutes: function (val) { return val * this.seconds(60); },
  hours: function (val) { return val * this.minutes(60); },
  days: function (val) { return val * this.hours(24); },
  weeks: function (val) { return val * this.days(7); },
  years: function (val) { return val * this.days(365); }, // TODO (udi) Wrong!
};

module.exports.ether = function(n) {
  return new web3.BigNumber(web3.toWei(n, 'ether'));
}