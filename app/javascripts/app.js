/*jshint esversion: 6 */

import 'jquery'
import 'bootstrap'
import {default as bootbox} from 'bootbox'
import {default as Clipboard} from 'clipboard'

import "../stylesheets/app.css";  // Import the page's CSS. Webpack will know what to do with it.
require("../help.md");

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract';
// import { default as clipboard } from 'clipboard';
// import clippy_img from '!!file!../images/clippy.svg'
/*
 * When you compile and deploy your Voting contract,
 * truffle stores the abi and deployed address in a json
 * file in the build directory. We will use this information
 * to setup a Voting abstraction. We will use this abstraction
 * later to create an instance of the Voting contract.
 * Compare this against the index.js from our previous tutorial to see the difference
 * https://gist.github.com/maheshmurthy/f6e96d6b3fff4cd4fa7f892de8a1a1b4#file-index-js
 */

import twoKeyAdmin_artifacts from '../../build/contracts/TwoKeyAdmin.json'
import twoKeyContract_artifacts from '../../build/contracts/TwoKeyContract.json'

var TwoKeyAdmin = contract(twoKeyAdmin_artifacts);
var TwoKeyContract = contract(twoKeyContract_artifacts);

var coinbase = '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1';

String.prototype.hashCode = function() {
  var hash = 0, i, chr;
  if (this.length === 0) return hash;
  for (i = 0; i < this.length; i++) {
    chr   = this.charCodeAt(i);
    hash  = ((hash << 5) - hash) + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
};

function whoAmI() {
    var whoami = $("#user-name").html();
    if (whoami === 'coinbase') {
        return coinbase;
    }
    if (whoami.startsWith('0x')) {
        return whoami;
    }
    var accounts = web3.eth.accounts;
    var n = accounts.length;
    return accounts[whoami.hashCode() % n];
}

window.login = function() {
    var username = $("#login-user-name").val();
    if (username.length < 3) {
        tempAlert('Name to short',2000);
        return;
    }
    $("#user-name").html(username);
    $("#login-user-name").val("");
    localStorage.username = username;
    lookupUserInfo();
}
window.logout = function() {
    delete localStorage.username;
    $("#user-name").html("");

    $(".login").show();
    $(".logout").hide();
}

window.getETH = function() {
    var myaddress = whoAmI();
    TwoKeyAdmin.deployed().then(function(contractInstance) {
        contractInstance.fundtransfer(myaddress, web3.toWei(1.0, 'ether'),
            {gas: 3000000, from: myaddress}).then(function() {
        }).catch(function (e) {
            alert(e);
        });
    }).catch(function (e) {
        alert(e);
    });
}

window.giveETH = function() {
    var myaddress = whoAmI();
    web3.eth.sendTransaction({from:myaddress, to:TwoKeyAdmin.address, value: web3.toWei(1, "ether")});
}

window.buy = function(twoKeyContractAddress, name, cost) {
    var myaddress = whoAmI();
    var ok = confirm("your about to buy the product \"" + name + "\" from contract \n" + twoKeyContractAddress +
      "\nfor " + cost + " ETH");
    if (ok) {
      TwoKeyContract.at(twoKeyContractAddress).then(function(TwoKeyContract_instance) {
        TwoKeyContract_instance.buyProduct({gas: 1400000, from: myaddress, value: web3.toWei(cost, "ether")}).then(function () {
            console.log('buy');
            lookupUserInfo();
        }).catch(function (e) {
            alert(e);
        });
      });
        //
        // web3.eth.sendTransaction({
        //     from: myaddress,
        //     to: twoKeyContractAddress,
        //     gas: 3000000000,
        //     value: web3.toWei(cost, "ether")
        // })
    }
}

window.redeem = function(twoKeyContractAddress) {
    var ok = confirm("your about to redeem the balance of 2Key contract \n" + twoKeyContractAddress);
    if (ok) {
        TwoKeyContract.at(twoKeyContractAddress).then(function (TwoKeyContract_instance) {
            var myaddress = whoAmI();
            TwoKeyContract_instance.redeem({gas: 1400000, from: myaddress}).then(function () {
                console.log('redeem')
                lookupUserInfo();
            });
        });
    }
}

function AdminInfo() {
 // TwoKeyAdmin.deployed().then(function(contractInstance) {
 //   $("#admin-address").html(contractInstance.address.toString());
 //   web3.eth.getBalance(contractInstance.address, function(error, result) {
 //     $("#admin-balance").html(web3.fromWei(result.toString()) + " ETH");
 //   });
 // });
}

function tempAlert(msg,duration)
{
        bootbox.alert(msg, function() {
                        console.log("Alert Callback");
                    });
        window.setTimeout(function(){
            bootbox.hideAll();
        }, duration);
}

// https://www.sitepoint.com/get-url-parameters-with-javascript/
function getAllUrlParams(url) {

  // get query string from url (optional) or window
  var queryString = url ? url.split('?')[1] : window.location.search.slice(1);

  // we'll store the parameters here
  var obj = {};

  // if query string exists
  if (queryString) {

    // stuff after # is not part of query string, so get rid of it
    queryString = queryString.split('#')[0];

    // split our query string into its component parts
    var arr = queryString.split('&');

    for (var i=0; i<arr.length; i++) {
      // separate the keys and the values
      var a = arr[i].split('=');

      // in case params look like: list[]=thing1&list[]=thing2
      var paramNum = undefined;
      var paramName = a[0].replace(/\[\d*\]/, function(v) {
        paramNum = v.slice(1,-1);
        return '';
      });

      // set parameter value (use 'true' if empty)
      var paramValue = typeof(a[1])==='undefined' ? true : a[1];

      // (optional) keep case consistent
      paramName = paramName.toLowerCase();
      paramValue = paramValue.toLowerCase();

      // if parameter name already exists
      if (obj[paramName]) {
        // convert value to array (if still string)
        if (typeof obj[paramName] === 'string') {
          obj[paramName] = [obj[paramName]];
        }
        // if no array index number specified...
        if (typeof paramNum === 'undefined') {
          // put the value on the end of the array
          obj[paramName].push(paramValue);
        }
        // if array index number specified...
        else {
          // put the value at that index number
          obj[paramName][paramNum] = paramValue;
        }
      }
      // if param name doesn't exist yet, set it
      else {
        obj[paramName] = paramValue;
      }
    }
  }

  return obj;
}

window.paste_address = function(elm) {
  let t = elm.innerHTML;
  $("#influence-address").val(t);
  $("#buy-address").val(t);
}

window.copy_link = function(twoKeyContractAddress, myaddress) {
    var link = location.origin + "/?c=" + twoKeyContractAddress + "&f=" + myaddress;
    alert(link);
}

function product_cleanup() {
  $("#product-name").val("");
  $("#product-symbol").val("");
  $("#total-arcs").val("");
  $("#quota").val("");
  $("#cost").val("");
  $("#total-units").val("");
  $("#bounty").val("");
  // $("#expiration").val("");
    $("#add-contract").show();
    $("#create-contract").hide();
}

// https://mostafa-samir.github.io/async-iterative-patterns-pt1/
function IterateOver(list, iterator, callback) {
    // this is the function that will start all the jobs
    // list is the collections of item we want to iterate over
    // iterator is a function representing the job when want done on each item
    // callback is the function we want to call when all iterations are over

    var doneCount = 0;  // here we'll keep track of how many reports we've got

    function report() {
        // this function resembles the phone number in the analogy above
        // given to each call of the iterator so it can report its completion

        doneCount++;

        // if doneCount equals the number of items in list, then we're done
        if(doneCount === list.length)
            callback();
    }

    // here we give each iteration its job
    for(var i = 0; i < list.length; i++) {
        // iterator takes 2 arguments, an item to work on and report function
        iterator(list[i], report)
    }
}


function contract_table(tbl, contracts, min_arcs) {
    $(tbl).empty();
    if (contracts.length == 0) {
        return;
    }
    $(tbl + "-spinner").addClass('spin');
    $(tbl + "-spinner").show();

    var myaddress = whoAmI();

    var first_row = true;
    function iterator(twoKeyContractAddress, report) {
        var take_link = location.origin + "/?c=" + twoKeyContractAddress + "&f=" + myaddress;
        TwoKeyContract.at(twoKeyContractAddress).then(function (TwoKeyContract_instance) {
            TwoKeyContract_instance.getInfo(myaddress).then(function (info) {
                var arcs, units, xbalance, name, symbol, total_arcs, quota, cost, bounty, total_units, balance;
                [arcs, units, xbalance, name, symbol, cost, bounty, quota, total_arcs, total_units, balance] = info;
                if ((arcs >= min_arcs) || (xbalance > 0)) {
                    balance = web3.fromWei(balance);
                    xbalance = web3.fromWei(xbalance);
                    cost = web3.fromWei(cost.toString());
                    bounty = web3.fromWei(bounty.toString());
                    if (first_row) {
                        $(tbl).append("<tr><td colspan=\"3\" data-toggle='tooltip' title='what I have in the contract'>Me</td><td colspan=\"9\" data-toggle='tooltip' title='contract properties'>Contract</td></tr>");
                        $(tbl).append("<tr>" +
                            "<td data-toggle='tooltip' title='number of ARCs I have in the contract'>ARCs</td>" +
                            "<td data-toggle='tooltip' title='Number of units I bought'>units</td>" +
                            "<td data-toggle='tooltip' title='ETH I have in the contract. click to redeem'>ETH</td>" +
                            "<td data-toggle='tooltip' title='contract/product name'>name</td>" +
                            "<td data-toggle='tooltip' title='contract symbol'>symbol</td>" +
                            "<td data-toggle='tooltip' title='how many ARCs an influencer or a customer will receive when opening the 2Key link of this contract'>take</td>" +
                            "<td data-toggle='tooltip' title='cost of buying the product sold in the contract. click to buy'>cost</td>" +
                            "<td data-toggle='tooltip' title='total amount that will be taken from the cost and be distributed between influencers'>bounty</td>" +
                            "<td data-toggle='tooltip' title='number of units being sold'>units</td>" +
                            "<td data-toggle='tooltip' title='total balance of ETH deposited in contract'>ETH</td>" +
                            "<td data-toggle='tooltip' title='total number of ARCs in the contract'>ARCs</td>" +
                            "<td data-toggle='tooltip' title='the address of the contract'>address</td>" +
                            "</tr>");
                        first_row = false;
                    }
                    $(tbl).append("<tr><td>" +
                        arcs + "</td><td>" +
                        units + "</td><td>" +
                        "<button class='bt' onclick='redeem(\"" + twoKeyContractAddress + "\")'" +
                        "='tooltip' title='redeem'" +
                        "\">" + xbalance +
                        "</button></td><td>" +
                        name + "</td><td>" +
                        symbol + "</td><td>" +
                        "<button class='lnk0 bt' " +
                        "data-toggle='tooltip' title='copy to clipboard a 2Key link for this contract'" +
                        "msg='2Key link was copied to clipboard. Someone else opening it will take one ARC from you'" +
                        "data-clipboard-text=\"" + take_link + "\">" + quota +
                        "</button></td><td>" +
                        "<button class='bt' onclick='buy(\"" + twoKeyContractAddress + "\",\"" + name + "\"," + cost + ")'" +
                        "='tooltip' title='buy'" +
                        "\">" + cost +
                        "</button></td><td>" +
                        bounty + "</td><td>" +
                        total_units + "</td><td>" +
                        balance + "</td><td>" +
                        total_arcs + "</td><td>" +
                        "<button class='lnk bt' " +
                        "data-toggle='tooltip' title='copy to clipboard' " +
                        "msg='contract address was copied to clipboard'>" +
                        twoKeyContractAddress + "</button>" +
                        "</td></tr>");
                }
                report();
            });
        });
    }

    function callback() {
        $(tbl + "-spinner").removeClass('spin');
        $(tbl + "-spinner").hide();
    }

    IterateOver(contracts, iterator, callback);
}

function populateMy2KeyContracts() {
    TwoKeyAdmin.deployed().then(function (contractInstance) {
        contractInstance.getOwner2Contracts(whoAmI()).then(function (my_contracts) {
            contract_table("#my-2key-contracts", my_contracts, 0);
            contractInstance.getContracts().then(function (all_contracts) {
                all_contracts = all_contracts.filter(contract => ! my_contracts.includes(contract));
                contract_table("#my-2key-arcs", all_contracts, 1);
            });
        });
    });
}

window.giveARCs = function() {
  let twoKeyContractAddress = $("#influence-address").val();
  let target = $("#target-address").val();
  if (!target || !twoKeyContractAddress) {
      alert("specify contract and target user");
      return;
  }

  var myaddress = whoAmI();

  TwoKeyContract.at(twoKeyContractAddress).then(function(TwoKeyContract_instance) {
      TwoKeyContract_instance.transfer(target, 1, {gas: 1400000, from: myaddress}).then(
          function(tx) {
              console.log(tx);
              $("#target-address").val("");
              $("#influence-address").val("");
              populateMy2KeyContracts();
          }).catch(function(e){
              alert(e);
      });
  });
}

function takeARCs(twoKeyContractAddress, target) {

  TwoKeyContract.at(twoKeyContractAddress).then(function(TwoKeyContract_instance) {
      TwoKeyContract_instance.quota().then(function (quota) {

          var ok = confirm("your about to take 1 ARC from user\n" + target +
              "\nin contract\n" + twoKeyContractAddress +
              "\nand this will turn into " + quota + " ARCs in your account");
          if (ok) {
              var myaddress = whoAmI();
              TwoKeyContract_instance.transferFrom(target, myaddress, 1, {
                  gas: 1400000,
                  from: myaddress
              }).then(
                  function (tx) {
                      console.log(tx);
                      $("#target-address").val("");
                      $("#influence-address").val("");
                      populateMy2KeyContracts();
                      location.assign(location.protocol + "//" + location.host);
                  }
              ).catch(function (e) {
                  alert("you can't take more than once\n\n" + e);
                  location.assign(location.protocol + "//" + location.host);
             });
          }
      });
  }).catch(function (e) {
        alert(e);
        location.assign(location.protocol + "//" + location.host);
    });
}

window.buyContract = function() {
    alert("not implemented")
}

window.addContract = function() {
    $("#add-contract").hide();
    $("#create-contract").show();
}

window.cancelContract = function() {
    product_cleanup();
}

window.createContract = function() {
  let name = $("#product-name").val();
  let symbol = $("#product-symbol").val();
  let total_arcs = $("#total-arcs").val();
  let quota = $("#quota").val();
  let cost = $("#cost").val();
  let total_units = $("#total-units").val();
  let bounty = $("#bounty").val();
  let productExpiration = $("#product-expiration").val();

  product_cleanup();

  /* TwoKeyAdmin.deployed() returns an instance of the contract. Every call
   * in Truffle returns a promise which is why we have used then()
   * everywhere we have a transaction call
   */
  TwoKeyAdmin.deployed().then(function(contractInstance) {
    let address = whoAmI();
    // value: web3.toWei(0.001, 'ether'),
    contractInstance.createTwoKeyContract(name, symbol, parseInt(total_arcs),
        parseInt(quota), web3.toWei(parseFloat(cost), 'ether'), web3.toWei(parseFloat(bounty), 'ether'), parseInt(total_units),
        {gas: 3000000, from: address}).then(function() {
      // return contractInstance.totalVotesFor.call(candidateName).then(function(v) {
      //   $("#" + div_id).html(v.toString());
        populateMy2KeyContracts();
    }).catch(function (e) {
        alert(e);
    });
  }).catch(function (e) {
        alert(e);
    });
  AdminInfo();
}

/* The user enters the total no. of tokens to buy. We calculate the total cost and send it in
 * the request. We have to send the value in Wei. So, we use the toWei helper method to convert
 * from Ether to Wei.
 */

/*
window.buyTokens = function() {
  let tokensToBuy = $("#buy").val();
  let price = tokensToBuy * tokenPrice;
  $("#buy-msg").html("Purchase order has been submitted. Please wait.");
  Voting.deployed().then(function(contractInstance) {
    contractInstance.buy({value: web3.toWei(price, 'ether'), from: web3.eth.accounts[0]}).then(function(v) {
      $("#buy-msg").html("");
      web3.eth.getBalance(contractInstance.address, function(error, result) {
        $("#contract-balance").html(web3.fromWei(result.toString()) + " Ether");
      });
    })
  });
  populateTokenData();
}
*/

function lookupUserInfo() {
  let address = whoAmI(); // $("#voter-info").val();
    if (!address) {
        alert("Unlock MetaMask and reload page");
    }
    $("#user-address").html(address.toString());
    web3.eth.getBalance(address, function(error, result) {
      $("#user-balance").html(web3.fromWei(result.toString()) + " ETH");
    });
  populateMy2KeyContracts();
  $(".login").hide();
  $(".logout").show();
}

/* Instead of hardcoding the candidates hash, we now fetch the candidate list from
 * the blockchain and populate the array. Once we fetch the candidates, we setup the
 * table in the UI with all the candidates and the votes they have received.
 */

// function populateCandidates() {
//   Voting.deployed().then(function(contractInstance) {
//     contractInstance.allCandidates.call().then(function(candidateArray) {
//       for(let i=0; i < candidateArray.length; i++) {
//         /* We store the candidate names as bytes32 on the blockchain. We use the
//          * handy toUtf8 method to convert from bytes32 to string
//          */
//         candidates[web3.toUtf8(candidateArray[i])] = "candidate-" + i;
//       }
//       setupCandidateRows();
//       populateCandidateVotes();
//       populateTokenData();
//     });
//   });
// }

/*
function populateCandidateVotes() {
  let candidateNames = Object.keys(candidates);
  for (var i = 0; i < candidateNames.length; i++) {
    let name = candidateNames[i];
    Voting.deployed().then(function(contractInstance) {
      contractInstance.totalVotesFor.call(name).then(function(v) {
        $("#" + candidates[name]).html(v.toString());
      });
    });
  }
}

function setupCandidateRows() {
  Object.keys(candidates).forEach(function (candidate) { 
    $("#candidate-rows").append("<tr><td>" + candidate + "</td><td id='" + candidates[candidate] + "'></td></tr>");
  });
}
*/

/* Fetch the total tokens, tokens available for sale and the price of
 * each token and display in the UI
 */
/*
function populateTokenData() {
  Voting.deployed().then(function(contractInstance) {
    contractInstance.totalTokens().then(function(v) {
      $("#tokens-total").html(v.toString());
    });
    contractInstance.tokensSold.call().then(function(v) {
      $("#tokens-sold").html(v.toString());
    });
    contractInstance.tokenPrice().then(function(v) {
      tokenPrice = parseFloat(web3.fromWei(v.toString()));
      $("#token-cost").html(tokenPrice + " Ether");
    });
    web3.eth.getBalance(contractInstance.address, function(error, result) {
      $("#contract-balance").html(web3.fromWei(result.toString()) + " Ether");
    });
  });
}
*/

function init() {
  TwoKeyAdmin.setProvider(web3.currentProvider);
  TwoKeyContract.setProvider(web3.currentProvider);


  var username = localStorage.username;
  if(((typeof username != "undefined") &&
     (typeof username.valueOf() == "string")) &&
    (username.length > 0)) {
      $("#user-name").html(username);
      setTimeout(lookupUserInfo(),0);
  } else {
      window.logout();
  }

  product_cleanup();

  var params = getAllUrlParams();
  if (params.c && params.f) {
      var myaddress = whoAmI();
      if (params.f == myaddress) {
          alert("You can't take your own ARCs. Switch to a different user and try again.");
          location.assign(location.protocol + "//" + location.host);
      } else {
          function myTimer() {
              takeARCs(params.c, params.f);
          }
          setTimeout(myTimer, 0);
      }
  }
}

$( document ).ready(function() {
    // https://clipboardjs.com/
    var clipboard_lnk0 = new Clipboard('.lnk0');

    clipboard_lnk0.on('success', function(e) {
        console.info('Action:', e.action);
        console.info('Text:', e.text);
        console.info('Trigger:', e.trigger);
        var msg = e.trigger.getAttribute('msg');
        tempAlert(msg,3000);
        e.clearSelection();
    });

    clipboard_lnk0.on('error', function(e) {
        console.error('Action:', e.action);
        console.error('Trigger:', e.trigger);
    });
    var clipboard_lnk = new Clipboard('.lnk',
        {
            text: function (trigger) {
                return trigger.innerHTML;
            }
        }
    );
    clipboard_lnk.on('success', function(e) {
        console.info('Action:', e.action);
        console.info('Text:', e.text);
        console.info('Trigger:', e.trigger);
        var msg = e.trigger.getAttribute('msg');
        tempAlert(msg,2200);
        e.clearSelection();
    });

    clipboard_lnk.on('error', function(e) {
        console.error('Action:', e.action);
        console.error('Trigger:', e.trigger);
    });

  var url = "http://"+window.document.location.hostname+":8545";
  if (typeof web3 !== 'undefined') {
    $(".login").hide();
    $(".logout").hide();
    $("#metamask-login").text("Make sure MetaMask is configured to use the test network " + url);

    $("#metamask-login").show();
      $("#logout-button").hide();
    localStorage.username = "MetaMask";

    console.warn("Using web3 detected from external source like Metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
    web3.version.getNetwork((err, netId) => {
        var ok = false;
        switch (netId) {
        case "1":
          console.log('This is mainnet');
          break
        case "2":
          console.log('This is the deprecated Morden test network.');
          break
        case "3":
          console.log('This is the ropsten test network.');
          break
        case "4":
          console.log('This is the Rinkeby test network.');
          break
        case "42":
          console.log('This is the Kovan test network.');
          break
        default:
          console.log('This is an unknown network.');
          ok = true;
        }
        if (ok) {
            $("#metamask-login").hide();
            init();
        } else {
            alert("Configure MetaMask to work on the following network "+url);
        }
    });
  } else {
      if (localStorage.username == "MetaMask") {
          delete localStorage.username;
      }
      $("#logout-button").show();
      $("#metamask-login").hide();
    console.warn("No web3 detected. Falling back to " + url +
        ". You should remove this fallback when you deploy live, " +
        "as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider(url));
    init();
  }
});
