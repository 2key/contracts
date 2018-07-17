## Install

on osx:
```bash
latest version 9.4 from https://nodejs.org/en/
```

### cleaning up
If things stop working for you then maybe npm got all mixed up:

```angular2html
rm -rf node_modules/
rm -rf build/
npm cache clean --force
```

### regular install
make sure your anti-virus software is turned off before running `npm install...`
```
npm install
npm install -g truffle
npm install -g ganache-cli
```

## Running

In one window run

```angular2html
ganache-cli -d
```
this will simulate the blockchain locally.
You can do this operation in any directory.

running a full node of ether takes a lof ot time to download. for dev, there's a dev chain that takes just a few hours
but here, we're just running a simulator that starts a new chain just for our use, named `ganache-cli`, and it only has 1 node.

deploy the contracts

```angular2html
truffle migrate --reset # need to be done every time after starting ganaches 
```

### running local web App
```angular2html
npm run dev 
```
node.js is the javascript engine from chrome changed to become a full language in which you can use javascript for backend as well.
npm is the package manager of node.

open browser at [http://localhost:8080](http://localhost:8080)


# Running demo on AWS
```angular2html
# login
# EC2
# Lunch
# select Ubuntu Server 16.04 LTS (HVM), SSD Volume Type - ami-da05a4a0
# select t2-large
# select secure policy to allow inbound TCP connection from anywhere on ports 8080,8545, 5001
# and press Review and Lunch
# select ssh key you have (e.g. 2k2.pem) click "I accept..."
# View Instance (bottom right)
# notice Public IP of your instance (e.g. ec2-18-218-88-210.us-east-2.compute.amazonaws.com)
# wait
ssh -a ~/amazon/keys/2k2.pem ubuntu@ec2-18-218-88-210.us-east-2.compute.amazonaws.com
# yes
# inside AWS EC2 instance
sudo apt-get update
sudo apt-get upgrade

git config --global credential.helper 'cache --timeout=3600'  # run this only once on the machine
git clone https://github.com/2keynet/web3-alpha.git
# enter user name/password for github
git checkout <branch>

curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g ganache-cli
# run ganache a blockchain simulator in the background
# -d run ganache determinsticly so we will have the same accounts each time
# -a 1000 generate 1K accounts
ganache-cli -d -a 1000 2>1 > /dev/null &

sudo npm install
sudo npm install -g truffle
# truffle compile  # not needed
truffle migrate --reset  # overwride the previous contract with same name
# run web server in the backgound
npm run dev  2>1 > /dev/null &
```
Now on your local machine open [http://localhost:8080](http://localhost:8080)

Or you can run firefox on the AWS EC2 instance itself.
First install X11 server on your local machine. Follow instructions at 
https://www.xquartz.org/.
Next connect to the AWS EC2 instance with this ssh command
```
ssh -i udi1.pem -Y ubuntu@34.207.63.53
```
Now install and run firefox on the remote machine:
```
sudo apt install -y firefox
firefox http://localhost:8080
```

# IPS
https://github.com/ipfs/js-ipfs-api/tree/master/examples/bundle-webpack
## Install
### OSX
```angularjs
wget https://dist.ipfs.io/go-ipfs/v0.4.13/go-ipfs_v0.4.13_darwin-amd64.tar.gz
tar xvfz go-ipfs_v0.4.13_darwin-amd64.tar.gz
cd go-ipfs
sudo ./install.sh
```
### AWS
```angularjs
sudo apt-get update
sudo apt-get install golang-go -y
wget https://dist.ipfs.io/go-ipfs/v0.4.13/go-ipfs_v0.4.13_linux-386.tar.gz
tar xvfz go-ipfs_v0.4.13_linux-386.tar.gz
sudo mv go-ipfs/ipfs /usr/local/bin/ipfs
```
Allow access to port `5001`

### Run
TODO the following has zero security
```angularjs
ipfs init
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin "[\"*\"]"
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Credentials "[\"true\"]"
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8082
ipfs daemon
```
make sure your in the project root
```angularjs
npm i ipfs-api
```

# DEPLOYING SOL CONTRACTS

### Flow:
Hack -> Commit&Push -> Deploy -> Generate JS solInterface for client -> Commit&Add tag -> Push everywhere

* Make sure that you have submodule in ./build/sol-interface
* Before runing mke sure that you are in HEAD of current branch and don't have uncommited changes (or incomming)
* To setup truffle change truffle-template.js it will be copied to truffle.js on deploy process run
* Run deployment with code:
```
node SOLDeployer.js migrate --network development --reset
```
All params that you pass to script will pass them to truffle command ex:
```
node SOLDeployer.js migrate --network rinkeby-infura
```
equal
```
truffle migrate --network rinkeby-infure
```

### Troubleshooting
* Script determinate branch checkout and creat new but better to handle this process by hand. Don't forget to --set-origin for branch to avoid push issues
* If you have submodule HEAD detached (branch HEAD or random hash). Goto build/sol-interface -> checkout to master or other working branch -> remove local broken branch -> run again

if you create a new branch make sure that you set-origin to be able push
if you have HEAD detached error you can reset sol-interface current branch

