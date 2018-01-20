## Install

on osx:
```bash
brew install node
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
# select t2-medium and press Review and Lunch
# select ssh key you have (e.g. udi1) click "I accept..."
# View Instance (bottom right)
# notice Public IP of your instance (e.g. 34.207.63.53)
# wait
ssh -i udi1.pem -L 8080:0.0.0.0:8080 -L 8545:0.0.0.0:8545 ubuntu@34.207.63.53
# yes
# inside AWS EC2 instance
git config --global credential.helper 'cache --timeout=3600'  # run this only once on the machine
git clone https://github.com/2keynet/web3-alpha.git 
# enter user name/password for github

sudo apt-get update
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g ganache-cli
ganache-cli 2>1 > /dev/null & # blockchain simulator in the background

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
