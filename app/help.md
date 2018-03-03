[home](./)
## Usage
* login by either entering your name or using MetaMask (see below.)
Entering user name is for demo purposes and there is no password.
It may happen that different names will result in the same demo user.

* The application starts by displaying all contracts you either created or joined to.
* Information appears in tables, each row describes a different contract. Use the tooltips of the column names to understand each one of them.
* Some of the values displayed in the tables appear as buttons. Use their tooltips to understand what action will happen if you click on them.
For example, the buttons in the values for the following columns:
  * `name` - switch you into a single view for that contract.
  * `my 2key link` - copy to clipboard a shortened 2key link for the contract.
  If you paste the link in a browser you will also move into the single view display.
  You can use the link as a shortcut to your contract and the link can also 
  be used by other users to join the contract, in this case you will want to
  first logout before opening the link.
* Single contract view displayes a visual graph of the influencers and customers
 that used your 2key link directly or indirectly. If non exist then the graph will not be displayed.
 The contractor (root node, the creator of the contract) appears as a red circle.
 Converters (customers) appear as green circles and the path from them to the root is also colored green.
 For every node you can collapse/expand the nodes below it by clicking on it. When collapsed the node appears with gray interior.
 Each node has a tooltip with how much units it bought and how many customers it converted.

* Some actions will require you to spend some gas. The account you are using
 will be required to have a balance to cover the cost of the gas:
  * login for the first time
  * create a contract
  * join a contract
  * fulfill a contract (the gas is in addition to the cost of the unit)

## Using MetaMask
* install [MetaMask](https://metamask.io/) Chrome extension
* configure MetaMask to work with the private test network used by this Dapp
  * to the right of the address bar, click on the fox icon of the chrome extension
  * in the extension panel select the network on the top left.
  * Click on Custom RPC.
  * Copy the name of this site (for example `http://poc.2key.network`) and enter it to
`New RPC URL` with port `8545` (for example `http://poc.2key.network:8545`) 
* create an account that has some Ether to work with:
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
* With MetaMask you can also create and use account that does not have Ether:
  * In MetaMask switch to the new account and copy its address
  * switch to an another account which has Ether (see previous step)
  * Use the Send button to transfer Ether from that account to the account address you just copied.
  * switch back to the account to which you just sent Ether
  * refresh the 2Key Dapp page to show the new address selection
  
* Whenever you perform an action that require gas, a metamask dialog will pop.
You should confirm the transaction.
The dialog will show you an estimate of how much the transaction will cost.
Note that you will need to manually control the gas price and set it to 2 to get a realistice value.
  
