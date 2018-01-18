## Install

on osx:
```bash
brew install node
```

select a project you want to run. For example
```bash
cd stage0.5/
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
npm install ganache-cli
```

read the `README.md` file in that directory to complete installation

## Running

In one window run `testrpc` this will simulate the blockchain locally.
You can do this operation in any directory.

running a full node of ether takes a lof ot time to download. for dev, there's a dev chain that takes just a few hours
but here, we're just running a simulator that starts a new chain just for our use, named testrpc, and it only has 1 node.

deploy the contracts

```angular2html
truffle compile  # need to be done only once after change in contract code --> .sol --> build
truffle migrate  # need to be done every time after starting testrpc 
```

migrate puts 2 contracts on ethereum (Migrations, Twokey). 
you send a transaction to address 0 in ethereum, this is a convention in ethereum, in each transaction you can send code
in the data payload, in there you can send a script - a contract code compiled into ethereum machine language (EVM)
this code has to produce code, and that code is the contract address.

in web2.0, each transaction you send out, is saved into the block. all the 100K current nodes on ethereum are obliged to validate
the validity of each transaction. e.g. if your contract code fails while running, it's invalid. 

each time you change the code the contract gets a new address. 
the migrate contract manages a lookup table that you can always locate the latest code edition of the contract,
so you're always using the migrate address, and behind the scenes it maps to your latest address.

when you have the address of a contract, there's a simple way to lookup the content of the contract.
blockchain is the tech allowing concenzus on the transaction history.

ethereum is bitcoin with a layer above it, with the addition, that each transaction can contain a layer of code (script)
+ validation of the code for a transaction to be valid.





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


## Using MetaMask
* install [MetaMask](https://metamask.io/) Chrome extension
* to the right of the address bar, click on the fox icon of the chrome extension
* in the extension panel select the network on the top left. It should be Localhost 8545
* click on the switch user icon on the top right,
scroll down and click on Import Account,
paste private key which was printed when testrpc started running




screen -S foo
Then to reattach it, run


screen -r foo  # or use -x, as in
screen -x foo  # for "Multi display mode" (see the man page)


******
screen -S testrpc
testrpc 2>1 


screen -S devbc
truffle migrate
npm run dev  2>1

*******

to detach from a screen ctrl+a , then d

to kill a screen ctral+a, then K

to reattach to a a screen:

screen -d -r testrpc

