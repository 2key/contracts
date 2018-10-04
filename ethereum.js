const ganache = require('ganache-core');
const path = require('path');
const fs = require('fs');

if (!fs.existsSync(path.join(__dirname, 'build'))) {
  fs.mkdirSync(path.join(__dirname, 'build'));
}

const mainNetDbPath = path.join(__dirname, 'build', 'mainNet');
const syncNetDbPath = path.join(__dirname, 'build', 'syncNet');

if (!fs.existsSync(mainNetDbPath)) {
  fs.mkdirSync(mainNetDbPath);
}

if (!fs.existsSync(syncNetDbPath)) {
  fs.mkdirSync(syncNetDbPath);
}

const accounts = [
  { balance: '0x1337000000000000000000', secretKey: '0xd718529bf9e0a5365e3a3545b66a612ff29be12aba366b6e6e919bef1d3b83e2' },
  { balance: '0x1337000000000000000000', secretKey: '0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1' },
  { balance: '0x1337000000000000000000', secretKey: '0x6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c' },
  { balance: '0x1337000000000000000000', secretKey: '0x646f1ce2fdad0e6deeeb5c7e8e5543bdde65e86029e2fd9fc169899c440a7913' },
  { balance: '0x1337000000000000000000', secretKey: '0xadd53f9a7e588d003326d1cbf9e4a43c061aadd9bc938c843a79e7b4fd2ad743' },
  { balance: '0x1337000000000000000000', secretKey: '0x395df67f0c2d2d9fe1ad08d1bc8b6627011959b79c53d7dd6a3536a33ab8a4fd' },
  { balance: '0x1337000000000000000000', secretKey: '0xe485d098507f54e7733a205420dfddbe58db035fa577fc294ebd14db90767a52' },
  { balance: '0x1337000000000000000000', secretKey: '0xa453611d9419d0e56f499079478fd72c37b251a94bfde4d19872c44cf65386e3' },
  { balance: '0x1337000000000000000000', secretKey: '0x829e924fdf021ba3dbbc4225edfece9aca04b929d6e75613329ca6f1d31c0bb4' },
  { balance: '0x1337000000000000000000', secretKey: '0xb0057716d5917badaf911b193b12b910811c1497b5bada8d7711f758981c3773' },
  { balance: '0x1337000000000000000000', secretKey: '0x77c5495fbb039eed474fc940f29955ed0531693cc9212911efd35dff0373153f' },
  { balance: '0x1337000000000000000000', secretKey: '0x9125720a89c9297cde4a3cfc92f233da5b22f868b44f78171354d4e0f7fe74ec' },
];

const mnemonic = 'laundry version question endless august scatter desert crew memory toy attract cruel';

const mainNet = ganache.server({
  accounts,
  unlocked_accounts: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  network_id: 8086,
  host: '0.0.0.0',
  debug: true,
  ws: true,
  gasPrice: '0x77359400',
  gasLimit: '0x80000000',
  default_balance_ether: 10000,
  total_accounts: 12,
  mnemonic,
  logger: console,
  db_path: mainNetDbPath,
});

const eventsNet = ganache.server({
  accounts,
  unlocked_accounts: [0],
  network_id: 17,
  host: '0.0.0.0',
  debug: true,
  ws: true,
  gasPrice: '0x0',
  gasLimit: '0x80000000',
  default_balance_ether: 10000,
  total_accounts: 1,
  mnemonic,
  logger: console,
  db_path: syncNetDbPath,
});

mainNet.listen(8545, (err, res) => {
  console.log(err, res);
});

eventsNet.listen(18545, (err, res) => {
  console.log(err, res);
});


