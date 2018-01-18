[home](./)
## Usage
* login by either entering your name or using MetaMask (see below.)
Entering user name is for demo purposes and there is no password.
It may happen that different names will result in the same demo user. 
* Click on any address of contract or user to copy it to the clipboard

### Business
* If you are a business, click on the `Create Contract` button to create a contract.
Each `2Key Contract` is like a seperate ICO to sell your product.
This contract has `ARC` coins. Note that coins from different contracts do not mix.
Each influencer or customer can take, for free, one coin from you, so the number of
`ARC` coins you have determine how much influencers or customers you can have.
Supply all the necessary information:
  * `name` the product you are selling. It's a unique name to your `ARC` coins
  * `symbol` is a short code to identify the product and your `ARC` coins
  * Determine the total number of `ARCs` you want to start with.
  * When an influencer or customer take a coin from you they receive an amount of coins that you determine.
This multiplication factor is called `take`.
  * Define the `cost` in Ether of your product
  * Define how much Ether will be taken from this cost as `bounty`
which will be distributed eqally between the influencers
* All contracts you created will appear in a table. Each row describes a different contract.
You can click on some of the values in a row:
  * `take` will copy to the clipboard a `2Key link` (see below)
  * If someone else buys your product, your earning (`cost - bounty`) will appear in your `ME/ETH` column.
If you click on this value you can `redeeme` it to your own Ether wallet.

### Influencer
* If you are an influencer you need to login to the site and then get a `2Key link` and open the web page with it.
* contracts which you took will appear in `My ARCs` table
* you can now create your own `2Key links` by clicking on the take value and pass it to other influencers or customers

### Customer
* If you are a customer follow the same steps as an influencer and click on the `cost` to buy the product
* When you complete your purchase an amount of `bounty` Ether will be taken from
the `cost` and will be distributed equally in the chain of influencers from the business to you,
these amounts will appear in the `Me/ETH` column of the influencers
The amount leftover in the cost will be given to the business who created the 2Key contract.
This amount will appear in the `Me/ETH` column of the business  


## Using MetaMask
* install [MetaMask](https://metamask.io/) Chrome extension
* configure MetaMask to work with the private test network used by this Dapp
  * to the right of the address bar, click on the fox icon of the chrome extension
  * in the extension panel select the network on the top left.
  * Click on Custom RPC.
  * Copy the name of this site (for example `ec2-52-23-248-220.compute-1.amazonaws.com`) and enter it to
`New RPC URL` with port `8545` (for example `http://ec2-52-23-248-220.compute-1.amazonaws.com:8545`) 
* create an account that has some Ether to work with
  * click on the switch user icon on the top right,
scroll down and click on `Import Account`,
paste one of the following private keys and refresh the 2Key Dapp page to show the new address selection:
```angular2html
(0) 4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d
(1) 6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1
(2) 6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c
(3) 646f1ce2fdad0e6deeeb5c7e8e5543bdde65e86029e2fd9fc169899c440a7913
(4) add53f9a7e588d003326d1cbf9e4a43c061aadd9bc938c843a79e7b4fd2ad743
(5) 395df67f0c2d2d9fe1ad08d1bc8b6627011959b79c53d7dd6a3536a33ab8a4fd
(6) e485d098507f54e7733a205420dfddbe58db035fa577fc294ebd14db90767a52
(7) a453611d9419d0e56f499079478fd72c37b251a94bfde4d19872c44cf65386e3
(8) 829e924fdf021ba3dbbc4225edfece9aca04b929d6e75613329ca6f1d31c0bb4
(9) b0057716d5917badaf911b193b12b910811c1497b5bada8d7711f758981c3773
```
* using account that does not have Ether:
  * In MetaMask switch to the account and copy its address
  * switch to an another account which has Ether (see previous step)
  * Use the Send button to transfer Ether from that account to the account address you just copied.
  * switch back to the account to which you just sent Ether
  * refresh the 2Key Dapp page to show the new address selection

## Known problems
* Copy to clipboard of address or 2Key link does not work on iOS
* In order to open a `2Key link` you need to first login in the home address and only then attempt to open the `2Key link`
