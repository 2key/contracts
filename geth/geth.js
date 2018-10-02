const fs = require('fs');
const path = require('path');
const childProcess = require('child_process');
const Docker = require('dockerode');
const rmDir = require('rimraf');

if (process.argv.length < 3) {
  console.log('Usage: node geth.js start|stop|reset');
  console.log('Exiting');
  process.exit(1);
}

const datadir = path.join(__dirname, '../build', 'geth.dev');
const docker = new Docker({ socketPath: process.platform === 'win32' ? 'npipe:////./pipe/docker_engine' : '/var/run/docker.sock' });

const runDocker = args => new Promise((resolve, reject) => {
  console.log('Run docker', args.join(' '));
  const dockerSpawn = childProcess.spawn('docker', args);
  dockerSpawn.stdout.on('data', (data) => {
    console.log(data.toString('utf8'));
  });
  dockerSpawn.stderr.on('data', (data) => {
    console.log(data.toString('utf8'));
    // reject(data);
  });
  dockerSpawn.on('close', async (code) => {
    console.log('docker exit with code', code);
    if (code === 0) {
      resolve(code);
    } else {
      reject(code);
    }
  });
});

function stop() {
  return new Promise((resolve) => {
    let found = false;
    docker.listContainers({ all: true }, (err, containers) => {
      containers.forEach((containerInfo) => {
        if (containerInfo.Image === '2key/geth:dev') {
          found = true;
          console.log('Stopping private network...', containerInfo.Id);
          docker.getContainer(containerInfo.Id).stop(() => {
            docker.getContainer(containerInfo.Id).remove(resolve);
          });
        }
      });
      if (!found) {
        resolve();
      }
    });
  });
}

// function buildImage() {
//   return new Promise((resolve, reject) => {
//     docker.buildImage({
//       context: __dirname,
//       src: ['Dockerfile'],
//     }, { t: '2key/geth:dev' }, (err, res) => {
//       if (err) {
//         reject(err);
//       } else {
//         resolve(res);
//       }
//     });
//   });
// }

async function start() {
  const gethdir = path.join(__dirname, 'docker');
  const buildDockerArgs = ['build', '-t', '2key/geth:dev', __dirname];
  const runDockerArgs = [
    'run',
    '--name=GETH_DEV',
    '--cpus=0.5',
    '-p8545:8545',
    '-p8546:8546',
    '-v',
    `${datadir}:/geth/data`,
    '-v',
    `${gethdir}:/opt/geth`,
    '2key/geth:dev',
    '--datadir=/geth/data',
    '--nodiscover',
    '--rpc',
    '--rpcapi',
    'db,personal,eth,net,web3,debug,txpool,miner',
    '--rpccorsdomain',
    '*',
    '--rpcaddr=0.0.0.0',
    '--rpcport',
    '8545',
    '--rpcvhosts',
    '*',
    `--networkid=${process.argv[3] || '8086'}`,
    '--ws',
    '--wsaddr=0.0.0.0',
    '--wsport=8546',
    '--wsorigins',
    '*',
    '--mine',
    '--miner.threads',
    '1',
    '--gasprice',
    '2000000000',
    '--unlock',
    '0,1,2,3,4,5,6,7,8,9,10,11',
    '--password',
    '/opt/geth/passwords',
  ];
  if (!fs.existsSync(datadir)) {
    fs.mkdirSync(datadir);
  }
  try {
    await stop();
    console.log('Starting local private network...');
    await runDocker(buildDockerArgs);
    // await buildImage();
    await runDocker(runDockerArgs);
  } catch (err) {
    console.log(err.toString('utf8'));
    process.exit(1);
  }
}

async function reset() {
  try {
    await stop();
    console.log('Starting local private network...');
    if (fs.existsSync(datadir)) {
      rmDir(datadir, (err) => {
        if (err) {
          console.log(err.toString('utf8'));
          process.exit(1);
        } else {
          start();
        }
      });
    }
  } catch (err) {
    console.log(err.toString('utf8'));
    process.exit(1);
  }
}

switch (process.argv[2]) {
  case 'start': {
    start();
    break;
  }
  case 'stop': {
    stop();
    break;
  }
  case 'reset': {
    reset();
    break;
  }
  default: {
    console.log('Usage: node geth.js start|stop|reset');
    process.exit(1);
  }
}
