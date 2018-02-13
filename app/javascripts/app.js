/*jshint esversion: 6 */

import 'jquery'
import 'bootstrap'
import {default as bootbox} from 'bootbox'
import {default as Clipboard} from 'clipboard'

// http://bl.ocks.org/d3noob/8375092
// const d3 = require("d3");

var BIG_INT = 100000000000;

var entityMap = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
  '/': '&#x2F;',
  '`': '&#x60;',
  '=': '&#x3D;'
};

function escapeHtml (string) {
  return String(string).replace(/[&<>"'`=\/]/g, function (s) {
    return entityMap[s];
  });
}

function short_url(url,eid) {
    fetch("https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyBqmohu0JE5CRhQYq9YgbeV9ApvWFR4pA0",
        {method: 'POST',body: JSON.stringify({longUrl: url}),
            headers: new Headers({'Content-Type': 'application/json'}),
            // mode: 'cors'
        }).then(x => {
                return x.json();
            }).catch((e) => {
                console.log(e);
            }).then(x => {
                var surl = x.id;
                safe_cb(eid, () => {
                    $(eid).text(surl.slice(8));
                    $(eid).attr("data-clipboard-text", surl);
                });
            });
}

function safe_cb(eid,cb) {
    // call cb() only when $(eid) exists in the window
    var id = setInterval(frame, 300);
    function frame() {
        if ($(eid).length) {
            cb();
            clearInterval(id);
        }
    }
    frame();
}

function owner2name(owner,eid,cb) {
    TwoKeyAdmin_contractInstance.getOwner2Name(owner).then(function (_name) {
        safe_cb(eid, () => {$(eid).text(_name);});
        if (cb) {
            cb(_name);
        }
    });
}

var unique_id = 0;
var params;

import "../stylesheets/app.css";  // Import the page's CSS. Webpack will know what to do with it.
require("../help.md");
const crypto = require('crypto');
const buf = crypto.randomBytes(256).toString('hex');

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract';
// import { default as clipboard } from 'clipboard';
// import clippy_img from '!!file!../images/clippy.svg'

import twoKeyAdmin_artifacts from '../../build/contracts/TwoKeyAdmin.json'
import twoKeyContract_artifacts from '../../build/contracts/TwoKeyContract.json'

var TwoKeyAdmin = contract(twoKeyAdmin_artifacts);
var TwoKeyAdmin_contractInstance;

var TwoKeyContract = contract(twoKeyContract_artifacts);
var TwoKeyContract_instance;
var twoKeyContractAddress;

// We are using IPFS to store content for each product.
// The web site also contains an IPFS node and this App connects to it
const ipfsAPI = require('ipfs-api')
var ipfs = ipfsAPI(window.document.location.hostname, '5001');

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
    var username = localStorage.username;
    if(!username) {
        return;
    }
    var whoami = username;
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
    // $("#user-name").html(username);
    $("#login-user-name").val("");
    localStorage.username = username;

        var myaddress = whoAmI();
        TwoKeyAdmin_contractInstance.getOwner2Name(myaddress).then(function (_name) {
            // "0x0000000000000000000000000000000000000000"

            if(_name) {
                if (_name != username) {
                    alert("Sorry, demo name already in use, try a different one");
                    window.logout();
                } else {
                    lookupUserInfo();
                }
            } else {
                TwoKeyAdmin_contractInstance.addName(username,{gas: 3000000, from: myaddress}).then(function () {
                    lookupUserInfo();
                });
            }
        });
}
window.logout = function() {
    delete localStorage.username;
    $("#user-name").html("");

    new_user();
    $(".login").show();
}

window.getETH = function() {
    var myaddress = whoAmI();
    TwoKeyAdmin_contractInstance.fundtransfer(myaddress, web3.toWei(1.0, 'ether'),
        {gas: 3000000, from: myaddress}).then(function() {
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
    var ok = confirm("your about to fulfill (buy) the product \"" + name + "\" from contract \n" + twoKeyContractAddress +
      "\nfor " + cost + " ETH");
    if (ok) {
        TwoKeyContract.at(twoKeyContractAddress).then( (TwoKeyContract_instance) => {
        TwoKeyContract_instance.buyProduct({gas: 1400000, from: myaddress, value: web3.toWei(cost, "ether")}).then(function () {
            console.log('buy');
            lookupUserInfo();
        }).catch(function (e) {
            alert(e);
        });
        }).catch(function(e){
          alert(e);
        });
    }
}

window.redeem = function(twoKeyContractAddress) {
    var ok = confirm("your about to redeem the balance of 2Key contract \n" + twoKeyContractAddress);
    if (ok) {
        var myaddress = whoAmI();
        TwoKeyContract.at(twoKeyContractAddress).then( (TwoKeyContract_instance) => {
        TwoKeyContract_instance.redeem({gas: 1400000, from: myaddress}).then(function () {
            console.log('redeem')
            lookupUserInfo();
        }).catch(function (e) {
            alert(e);
        });
        }).catch(function(e){
          alert(e);
        });
    }
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
  $("#description").val("");
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

function contact_header() {
    var items = [];
    items.push("<td data-toggle='tooltip' title='number of ARCs I have in the contracts'>my ARCs</td>");
    items.push("<td data-toggle='tooltip' title='key link'>my 2key link</td>");
    items.push("<td data-toggle='tooltip' title='Number of units I bought'>my units</td>");
    items.push("<td data-toggle='tooltip' title='ETH I have in the contract. click to redeem'>my ETH</td>");
    items.push("<td data-toggle='tooltip' title='contract/product name'>name</td>");
    items.push("<td data-toggle='tooltip' title='contract symbol'>symbol</td>");
    items.push("<td data-toggle='tooltip' title='how many ARCs an influencer or a customer will receive when opening a 2Key link of this contract'>take</td>");
    items.push("<td data-toggle='tooltip' title='cost of buying the product sold in the contract. click to buy'>cost</td>");
    items.push("<td data-toggle='tooltip' title='total amount that will be taken from the cost and be distributed between influencers'>bounty</td>");
    items.push("<td data-toggle='tooltip' title='number of units being sold'>units</td>");
    items.push("<td data-toggle='tooltip' title='total balance of ETH deposited in contract'>ETH</td>");
    items.push("<td data-toggle='tooltip' title='total number of ARCs in the contract'>ARCs</td>");
    items.push("<td data-toggle='tooltip' title='product description'>description</td>");
    items.push("<td data-toggle='tooltip' title='who created the contract'>owner</td>");
    items.push("<td data-toggle='tooltip' title='the address of the contract'>address</td>");

    return items;
}

function contract_info(TwoKeyContract_instance, min_arcs, callback) {
    var items = [];
    var myaddress = whoAmI();
    var twoKeyContractAddress = TwoKeyContract_instance.address;
    var take_link = location.origin + "/?c=" + twoKeyContractAddress + "&f=" + myaddress;
    var contract_link = "./?c=" + twoKeyContractAddress;
    TwoKeyContract_instance.getInfo(myaddress).then(function (info) {
        var arcs, units, xbalance, name, symbol, total_arcs, quota, cost, bounty, total_units, balance, owner;
        [arcs, units, xbalance, name, symbol, cost, bounty, quota, total_arcs, total_units, balance, owner] = info;

        balance = web3.fromWei(balance);
        xbalance = web3.fromWei(xbalance);
        cost = web3.fromWei(cost.toString());
        bounty = web3.fromWei(bounty.toString());

        var onclick_buy = "buy('" + twoKeyContractAddress + "','" + name + "'," + cost + ")";
        var onclick_redeem = "redeem('" + twoKeyContractAddress + "')";
        $("#buy").attr("onclick", onclick_buy);
        $("#redeem").attr("onclick", onclick_redeem);


        if ((arcs >= min_arcs) || (xbalance > 0)) {

            if (arcs >= BIG_INT) {
                arcs = "&infin;";
            }
            if (total_arcs >= BIG_INT) {
                total_arcs = "&infin;";
            }
            if (quota >= BIG_INT) {
                quota = "&infin;";
            }

            items.push("<td>" + arcs + "</td>");
            unique_id = unique_id + 1;
            short_url(take_link, "#id" + unique_id);
            items.push("<td>" +
                "<button class='lnk0 bt' id=\"id" + unique_id + "\" " +
                "data-toggle='tooltip' title='copy to clipboard a 2Key link for this contract'" +
                "msg='2Key link was copied to clipboard. Someone else opening it will take one ARC from you'" +
                "data-clipboard-text=\"" + take_link + "\">" + take_link +
                "</button></td>");
            items.push("<td>" + units + "</td>");
            items.push("<td>" +
                "<button class='bt' onclick=\"" + onclick_redeem + "\"" +
                "data-toggle='tooltip' title='redeem'" +
                "\">" + xbalance +
                "</button></td>");
            items.push("<td><a href='" + contract_link + "'>"+ name + "</a></td>");
            items.push("<td>" + symbol + "</td>");
            items.push("<td>" + quota + "</td>");
            items.push("<td>" +
                "<button class='bt' onclick=\"" + onclick_buy + "\"" +
                "data-toggle='tooltip' title='buy'" +
                "\">" + cost +
                "</button></td>");
            items.push("<td>" + bounty + "</td>");
            items.push("<td>" + total_units + "</td>");
            items.push("<td>" + balance + "</td>");
            items.push("<td>" + total_arcs + "</td>");
            unique_id = unique_id + 1;
            var tag_description = "id" + unique_id;
            items.push("<td id=\"" + tag_description + "\" ></td>");
            TwoKeyContract_instance.ipfs_hash().then(ipfs_hash => {
                safe_cb("#" + tag_description, () => {
                    $("#" + tag_description).text(ipfs_hash);
                });
                if (ipfs_hash) {
                    ipfs.cat(ipfs_hash, (err, res) => {
                        if (err) throw err;
                        safe_cb("#" + tag_description, () => {
                            $("#" + tag_description).text(res.toString());
                        });
                    });
                }
            });

            unique_id = unique_id + 1;
            var tag_owner = "id" + unique_id;
            items.push("<td id=\"" + tag_owner + "\" ></td>");
            TwoKeyContract_instance.owner().then(owner => {
                safe_cb("#" + tag_owner, () => {
                    $("#" + tag_owner).text(owner);
                    owner2name(owner, "#" + tag_owner);
                });
            });

            items.push("<td>" +
                "<button class='lnk bt' " +
                "data-toggle='tooltip' title='copy to clipboard' " +
                "msg='contract address was copied to clipboard'>" +
                twoKeyContractAddress + "</button>" +
                "</td>");
        }
        callback(items);
    });
}

function contract_table(tbl, contracts, min_arcs) {
    $(tbl).empty();
    if (contracts.length == 0) {
        return;
    }
    $(tbl + "-spinner").addClass('spin');
    $(tbl + "-spinner").show();

    function add_row(h) {
        var header_row = "<tr>" + h.join() + "</tr>";
        // for(var i = 0; i < h.length; i++) {
        //     header_row += h[i];
        // }
        // header_row += "</tr>";
        $(tbl).append(header_row);
    }

    var first_row = true;
    function iterator(twoKeyContractAddress, report) {
        if (first_row) {
            first_row = false;
            $(tbl).append("<tr><td colspan=\"4\" data-toggle='tooltip' title='what I have in the contract'>Me</td><td colspan=\"11\" data-toggle='tooltip' title='contract properties'>Contract</td></tr>");
            add_row(contact_header());
        }

        function row_callback(items) {
            add_row(items)
            report();
        }
        TwoKeyContract.at(twoKeyContractAddress).then( (TwoKeyContract_instance) => {
            contract_info(TwoKeyContract_instance, min_arcs, row_callback);
        }).catch(function(e){
          alert(e);
        });
    }

    function callback() {
        $(tbl + "-spinner").removeClass('spin');
        $(tbl + "-spinner").hide();
    }

    IterateOver(contracts, iterator, callback);
}

function populateMy2KeyContracts() {
    TwoKeyAdmin_contractInstance.getOwner2Contracts(whoAmI()).then(function (my_contracts) {
        contract_table("#my-2key-contracts", my_contracts, 0);
        TwoKeyAdmin_contractInstance.getContracts().then(function (all_contracts) {
            all_contracts = all_contracts.filter(contract => ! my_contracts.includes(contract));
            contract_table("#my-2key-arcs", all_contracts, 1);
        });
    });
}

function populateContract() {
    $("#contract-table").empty();
    $("#contract-spinner").addClass('spin');
    $("#contract-spinner").show();
    var h = contact_header();
    function contract_callback(c) {
        for (var i = 0; i < h.length; i++) {
            var row = "<tr>" + h[i] + c[i] + "</tr>";
            $("#contract-table").append(row);
        }
        $("#contract-spinner").removeClass('spin');
        $("#contract-spinner").hide();
    }
    contract_info(TwoKeyContract_instance, -1, contract_callback);

    // var myaddress = whoAmI();
    // d3_root.address = myaddress;
    // d3_add_children(d3_root);
}

function populate() {
  if (params.c) {
      populateContract();
  } else {
      populateMy2KeyContracts();
  }
}

window.giveARCs = function() {
  let twoKeyContractAddress = $("#influence-address").val();
  let target = $("#target-address").val();
  if (!target || !twoKeyContractAddress) {
      alert("specify contract and target user");
      return;
  }

  var myaddress = whoAmI();
  TwoKeyContract.at(twoKeyContractAddress).then( (TwoKeyContract_instance) => {
  TwoKeyContract_instance.transfer(target, 1, {gas: 1400000, from: myaddress}).then((tx) => {
      console.log(tx);
      $("#target-address").val("");
      $("#influence-address").val("");
      populate();
  }).catch(function(e){
          alert(e);
  });
  }).catch(function(e){
          alert(e);
  });
}

window.contract_take = function() {
    var twoKeyContractAddress = params.c;
    var target = params.f;
    var myaddress = whoAmI();
    if (target == myaddress) {
        alert("You can't take your own ARCs. Switch to a different user and try again.");
        return;
    }
  TwoKeyContract.at(twoKeyContractAddress).then( (TwoKeyContract_instance) => {

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
                      populate();
                      location.assign(location.protocol + "//" + location.host);
                  }
              ).catch(function (e) {
                  alert("you can't take more than once\n\n" + e);
                  location.assign(location.protocol + "//" + location.host);
              });
          }
      }).catch(function (e) {
          alert(e);
      });
  }).catch(function(e){
          alert(e);
  });
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
  if (total_arcs) {
      total_arcs = parseInt(total_arcs);
  } else {
      total_arcs = BIG_INT;
  }
  let quota = $("#quota").val();
  if (quota) {
      quota = parseInt(quota);
  } else {
      quota = BIG_INT;
  }
  let cost = $("#cost").val();
  let total_units = $("#total-units").val();
  let bounty = $("#bounty").val();
  let productExpiration = $("#product-expiration").val();
  let description = $("#description").val();

  product_cleanup();

  if (description) {
    ipfs.add([Buffer.from(description)], (err, res) => {
      if (err) {
          alert(err);
          throw err
      }
      const ipfs_hash = res[0].hash;
      let address = whoAmI();
      // value: web3.toWei(0.001, 'ether'),
      TwoKeyAdmin_contractInstance.createTwoKeyContract(name, symbol, total_arcs, quota,
          web3.toWei(parseFloat(cost), 'ether'), web3.toWei(parseFloat(bounty), 'ether'),
          parseInt(total_units), ipfs_hash,
          {gas: 3000000, from: address}).then(function () {
          populate();
      }).catch(function (e) {
          alert(e);
      });
    });
  } else {
      let address = whoAmI();
      // value: web3.toWei(0.001, 'ether'),
      TwoKeyAdmin_contractInstance.createTwoKeyContract(name, symbol, total_arcs, quota,
          web3.toWei(parseFloat(cost), 'ether'), web3.toWei(parseFloat(bounty), 'ether'),
          parseInt(total_units), "",
          {gas: 3000000, from: address}).then(function () {
          populate();
      }).catch(function (e) {
          alert(e);
      });
  }
}

function lookupUserInfo() {
  var username = localStorage.username;
  $("#user-name").html(username);
  let address = whoAmI(); // $("#voter-info").val();
    if (!address) {
        alert("Unlock MetaMask and reload page");
    }
    $("#user-address").html(address.toString());
    web3.eth.getBalance(address, function(error, result) {
      $("#user-balance").html(web3.fromWei(result.toString()) + " ETH");
    });
  populate();
  new_user();
  $(".logout").show();
}

function ipfs_init() {
    ipfs.id((err, res) => {
          if (err) throw err;
          console.log(res.id);
          console.log(res.agentVersion);
          console.log(res.protocolVersion);
        });
}

function transfer_event(c,e) {
    // e.address;
    var from = e.args.from;
    var to = e.args.to;

    if(!c.given_to[from]) {
        c.given_to[from] = [];
    }
    c.given_to[from].push(to);
}

function fulfilled_event(c,e) {
    // e.address;
    var to = e.args.to;

    if(!c.units[to]) {
        c.units[to] = 0;
    }
    c.units[to]++;
}

function init(cb) {
  params = getAllUrlParams();
  if (params.c) {
    $("#contract").show();
    $("#contracts").hide();
  } else {
    $("#contracts").show();
    $("#create-contract").hide();
    $("#contract").hide();
    $("#buy").removeAttr("onclick");
    $("#redeme").removeAttr("onclick");
  }

  TwoKeyAdmin.setProvider(web3.currentProvider);

  TwoKeyContract.setProvider(web3.currentProvider);


  /* TwoKeyAdmin.deployed() returns an instance of the contract. Every call
   * in Truffle returns a promise which is why we have used then()
   * everywhere we have a transaction call
   */

  var twoKeyContractAddress = params.c;
  if (twoKeyContractAddress) {
      var p1 = TwoKeyContract.at(twoKeyContractAddress);
      var p2 = TwoKeyAdmin.deployed();
      Promise.all([p1, p2]).then(function (instances) {
          TwoKeyContract_instance = instances[0];
          TwoKeyContract_instance.given_to = {};
          TwoKeyContract_instance.units = {};

          // TwoKeyContract_instance.all_events = TwoKeyContract_instance.allEvents((error, log) => {
          //   if (!error)
          //       console.log(log);
          // });
          // TwoKeyContract_instance.all_events.get((error,logs) => {
          //   if (!error)
          //       console.log(logs);
          // });
          TwoKeyContract_instance.Transfer_event = TwoKeyContract_instance.Transfer({}, { fromBlock: 0, toBlock: 'latest' });
          // TwoKeyContract_instance.Transfer_event.watch(function(error, log){
          //     transfer_event(TwoKeyContract_instance, log);
          //   });
          TwoKeyContract_instance.Transfer_event.get((error,logs) => {
              for(var i=0; i<logs.length; i++) {
                  transfer_event(TwoKeyContract_instance, logs[i]);
              }
            d3_init();
          });

          TwoKeyContract_instance.Fulfilled_event = TwoKeyContract_instance.Fulfilled({}, { fromBlock: 0, toBlock: 'latest' });
          // TwoKeyContract_instance.Fulfilled_event.watch(function(error, log){
          //     fulfilled_event(TwoKeyContract_instance, log);
          //   });
          TwoKeyContract_instance.Fulfilled_event.get((error,logs) => {
              for(var i=0; i<logs.length; i++) {
                  fulfilled_event(TwoKeyContract_instance, logs[i]);
              }
            d3_init();
          });

          TwoKeyAdmin_contractInstance = instances[1];
          $("#loading").hide();
          cb();
      }).catch(function (e) {
          alert(e);
      });
  } else {
      TwoKeyAdmin.deployed().then(function (contractInstance) {
          TwoKeyAdmin_contractInstance = contractInstance;
          $("#loading").hide();
          cb();
      }).catch(function (e) {
          alert(e);
      });
  }
}

function new_user() {
    $("#influencers-graph-wrapper").hide();
    $(".login").hide();
    $(".logout").hide();
    $("#metamask-login").hide()
}

$( document ).ready(function() {
    $("#loading").show();
    new_user();

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
    // Use Mist/MetaMask's provider
    $("#metamask-login").text("Make sure MetaMask is configured to use the test network " + url);

    $("#metamask-login").show();
      $("#logout-button").hide();
    localStorage.username = "MetaMask";

    console.warn("Using web3 detected from external source like Metamask")
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

            function cb() {
                // Check if we have a name and if not, show login screen
                    var myaddress = whoAmI();
                    TwoKeyAdmin_contractInstance.getOwner2Name(myaddress).then(function (_name) {
                        if (_name) {
                            localStorage.username = _name;
                            setTimeout(lookupUserInfo(),0);
                        } else {
                            window.logout();
                        }
                    });
            }
            
            init(cb);
        } else {
            alert("Configure MetaMask to work on the following network "+url);
        }
    });
  } else {
      // not using MetaMask
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

    function cb() {
        if (localStorage.username) {
            TwoKeyAdmin_contractInstance.getName2Owner(localStorage.username).then(function (_owner) {
                var myaddress = whoAmI();
                if (myaddress == _owner) {
                    setTimeout(lookupUserInfo(), 0);
                } else {
                    window.logout();
                }
            });
        } else {
            $(".login").show();
        }
    }
    init(cb);
  }
  setTimeout(ipfs_init, 0);
});


// ************** Generate the tree diagram	 *****************
//http://bl.ocks.org/d3noob/8375092
// for d3.v4 see https://bl.ocks.org/mbostock/4339184
var margin = {top: 0, right: 0, bottom: 0, left: 50},
	width = 960 - margin.right - margin.left,
	height = 400 - margin.top - margin.bottom;

var tree = d3.layout.tree()
    .size([height, width]);    // Compute the new tree layout.

var d3_i = 0,
	duration = 750,
	d3_root;

var diagonal = d3.svg.diagonal()
	.projection(function(d) { return [d.y, d.x]; });

var svg = d3.select("#influencers-graph").append("svg")
	.attr("width", width + margin.right + margin.left)
	.attr("height", height + margin.top + margin.bottom)
  .append("g")
	.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

// Define the div for the tooltip
// http://bl.ocks.org/d3noob/a22c42db65eb00d4e369
var tooltip_div = d3.select("body").append("div")
    .attr("class", "tooltip")
    .style("opacity", 0);

var d3_init_counter = 0;
function d3_init() {
    // we have two inits. One from going over all Transfer events and one
    // from going over all Fulfilled events.
    if(++d3_init_counter < 2) {
        return;
    }

    // d3.select("#influencers-graph").style("height", "500px");
    d3.select(self.frameElement).style("height", "500px");

    var myaddress = whoAmI();
    if (myaddress) {
        var root = d3_add_event_children([myaddress], null, 1);
        if (root) {
            d3_root = root[0];
            d3_update(d3_root);
            $("#influencers-graph-wrapper").show();
        }
    }
}

function d3_update(source) {
    var nodes = tree.nodes(d3_root).reverse(),
        links = tree.links(nodes);

    // Normalize for fixed-depth.
    nodes.forEach(function (d) {
        d.y = d.depth * 180;
    });

    // Update the nodes…
    var node = svg.selectAll("g.node")
        .data(nodes, function (d) {
            return d.id || (d.id = ++d3_i);
        });

    // Enter any new nodes at the parent's previous position.
    var nodeEnter = node.enter().append("g")
        .attr("class", "node")
        .attr("transform", function (d) {
            return "translate(" + source.y0 + "," + source.x0 + ")";
        })
        .on("click", d3_click)
        .on("mouseover", function(d) {
            tooltip_div.transition()
                .duration(200)
                .style("opacity", .9);
            tooltip_div	.html("units "+d.units + "<br/>" + "rewards "+d.rewards + "<br/>")
                .style("left", (d3.event.pageX) + "px")
                .style("top", (d3.event.pageY - 28) + "px");
            })
        .on("mouseout", function(d) {
            tooltip_div.transition()
                .duration(500)
                .style("opacity", 0);
        });;

    nodeEnter.append("circle")
        .attr("r", 1e-6)
        .style("fill", function (d) {
            return d._children ? "lightsteelblue" : "#fff";
        });

    nodeEnter.append("text")
        .attr("x", function (d) {
            return d.children || d._children ? -13 : 13;
        })
        .attr("dy", ".35em")
        .attr("text-anchor", function (d) {
            return d.children || d._children ? "end" : "start";
        })
        .text(function (d) {
            return d.name || d.address;
        })
        .attr("id", function (d) {
            return 'd3-' + d.d3_id;
        })
        .style("fill-opacity", 1e-6);

    // Transition nodes to their new position.
    var nodeUpdate = node.transition()
        .duration(duration)
        .attr("transform", function (d) {
            return "translate(" + d.y + "," + d.x + ")";
        });

    nodeUpdate.select("circle")
        .attr("r", 10)
        .style("fill", function (d) {
            return d.load_children ? (d.load_children_in_progress ? "#0f0" : "#f00") : (d._children ? "lightsteelblue" : "#fff");
        }).style("stroke", (d) => {
            return (d.rewards || d.units) ? "#0f0" : "steelblue";
        });

    nodeUpdate.select("text")
        .style("fill-opacity", 1);

    // Transition exiting nodes to the parent's new position.
    var nodeExit = node.exit().transition()
        .duration(duration)
        .attr("transform", function (d) {
            return "translate(" + source.y + "," + source.x + ")";
        })
        .remove();

    nodeExit.select("circle")
        .attr("r", 1e-6);

    nodeExit.select("text")
        .style("fill-opacity", 1e-6);

    // Update the links…
    var link = svg.selectAll("path.link")
        .data(links, function (d) {
            return d.target.id;
        });

    link.style("stroke", (d) => {
            return (d.target.rewards || d.target.units) ? "#0f0" : "#ccc";
        });

    // Enter any new links at the parent's previous position.
    link.enter().insert("path", "g")
        .attr("class", "link")
        .attr("d", function (d) {
            var o = {x: source.x0, y: source.y0};
            return diagonal({source: o, target: o});
        });

    // Transition links to their new position.
    var linkUpdate = link.transition()
        .duration(duration)
        .attr("d", diagonal);

    linkUpdate.style("stroke", (d) => {
            return (d.target.rewards || d.target.units) ? "#0f0" : "#ccc";
        });

    // Transition exiting nodes to the parent's new position.
    link.exit().transition()
        .duration(duration)
        .attr("d", function (d) {
            var o = {x: source.x, y: source.y};
            return diagonal({source: o, target: o});
        })
        .remove();

    // Stash the old positions for transition.
    nodes.forEach(function (d) {
        d.x0 = d.x;
        d.y0 = d.y;
    });
}

// Toggle children on click.
function d3_click(d) {
    if (d.children) {
        d._children = d.children;
        d.children = null;
    } else {
        d.children = d._children;
        d._children = null;
    }
    d3_update(d);
}

function d3_add_event_children(addresses, parent, depth) {
    var childrens = [];

    if (addresses) {
        for (var i = 0; i < addresses.length; i++) {
            var address = addresses[i];

            var node = {
                "address": address,
                "d3_id": ++unique_id,
                "parent": parent,
                "units": 0,
                "rewards": 0,
                "x0": height / 2,
                "y0": 0
            };
            childrens.push(node);

            function d3_wrapper(node) {
                // freeze node
                return function d3_cb(_name) {
                    node.name = _name;
                }
            }

            owner2name(address, "#d3-" + node.d3_id, d3_wrapper(node));

            var _units = TwoKeyContract_instance.units[address];
            if (_units) {
                var n = node;
                n.units += parseInt("" + _units);
                n = n.parent;
                while (n) {
                    n.rewards += parseInt("" + _units);
                    n = n.parent;
                }
            }

            var c = d3_add_event_children(TwoKeyContract_instance.given_to[address], node, depth-1);
            if(depth>0) {
                node.children = c;
            } else {
                node._children = c;
            }
        }
    }

    if (childrens.length == 0) {
        return null;
    } else {
        return childrens;
    }
}