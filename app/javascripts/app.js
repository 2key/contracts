/* jshint esversion: 6 */

import 'jquery'
import 'bootstrap'
import {default as bootbox} from 'bootbox'
import {default as Clipboard} from 'clipboard'

// http://bl.ocks.org/d3noob/8375092
// const d3 = require("d3");

let BIG_INT = 100000000000

let entityMap = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
  '/': '&#x2F;',
  '`': '&#x60;',
  '=': '&#x3D;'
}

// When using metamask you cant make a transaction from inside a promise
// to over come this you can add a call-back function to this array which is
// pulled for execution
let timer_cbs = []
let timer_cbs_delayed = []

function safe_alert (e) {
  // when alert is called from within a promise it does not alwys so up
  // so instead push it to becalled later from the main timer
  function my_alert () {
    // freeze the error message
    return () => alert(e)
  }
  timer_cbs.push(my_alert())
}

function gastimate(gas) {
  if (localStorage.meta_mask)
    return
  return gas
}

// Transactions are calls to method on a contract that cause its state to change
// these transactions require gas to operate
// they take a long time (async)
// they can fail
// they could be nested
//
// we want the top part of the page to show whats happening
let transaction_count = 0
let total_gas = 0
let total_success = 0

let active_transactions = 0
let active_views = 0
let active_created = 0
let active_joined = 0
let active_fulfilled = 0

function transaction_msg () {
  let active = active_transactions + active_views + active_created + active_joined + active_fulfilled
  if (active) {
    $('#loader-circle').addClass('spin')
    $('.loader').show()
  } else {
    $('#loader-circle').removeClass('spin')
    $('.loader').hide()
  }
  $('#msg').text(
    'pending-transactions/views/created/joined/fulfilled=' + active_transactions + '/' + active_views + '/' +
    active_created + '/' + active_joined + '/' + active_fulfilled +
    ' total-gas/successful/transactions=' + total_gas + '/' + total_success + '/' + transaction_count
  )
}

function transaction_start (tx_promise, cb_end, cb_error) {
  function transaction_end(tx) {
    function te(tx) {
      if (tx.receipt) {
        total_gas += tx.receipt.gasUsed
        if (tx.receipt.status) {
          total_success += 1
        }
      } else {
        // this happens when creating new contract
        let receipt = web3.eth.getTransactionReceipt(tx.transactionHash)
        total_gas += receipt.gasUsed
        if (receipt.status) {
          total_success += 1
        }
      }
      active_transactions--
      transaction_msg()

      console.log(tx)

      // Every time a transaction ends there is a good chance that the user ETH balance has changed
      update_user_balance()

      if (cb_end) cb_end()
    }

    if ((typeof tx) == 'string') {
      console.log(tx)
      web3.eth.getTransactionReceipt(tx, te)
    } else {
      te(tx)
    }
  }

  function transaction_error(e) {
    active_transactions--
    transaction_msg()
    console.log(e)
    safe_alert(e.toString().split('\n')[0])
    if (cb_error) cb_error()
  }

  transaction_count++
  active_transactions++
  transaction_msg(true, "transaction")

  tx_promise.then(transaction_end).catch(transaction_error)
}

function view (view_promise, cb_end, cb_error) {
  function view_end(val) {
    active_views--
    transaction_msg()

    console.log(val)
    if (cb_end) cb_end(val)
  }

  function view_error(e) {
    active_views--
    transaction_msg()
    safe_alert(e)
    if (cb_error) cb_error()
  }

  active_views++
  transaction_msg()

  view_promise.then(view_end).catch(view_error)
}



function escapeHtml (string) {
  return String(string).replace(/[&<>"'`=\/]/g, function (s) {
    return entityMap[s]
  })
}

function short_url (url, eid) {
  fetch('https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyBqmohu0JE5CRhQYq9YgbeV9ApvWFR4pA0',
    {method: 'POST',
      body: JSON.stringify({longUrl: url}),
      headers: new Headers({'Content-Type': 'application/json'})
      // mode: 'cors'
    }).then(x => {
    return x.json()
  }).catch((e) => {
    safe_alert(e)
    console.log(e)
  }).then(x => {
    let surl = x.id
    safe_cb(eid, () => {
      $(eid).text(surl.slice(8))
      $(eid).attr('data-clipboard-text', surl)
    })
  })
}

function safe_cb (eid, cb) {
  // call cb() only when $(eid) exists in the window
  let id = setInterval(frame, 300)
  function frame () {
    if ($(eid).length) {
      cb()
      clearInterval(id)
    }
  }
  frame()
}

function owner2name (owner, eid, cb) {
  view(TwoKeyReg_contractInstance.getOwner2Name(owner),
    _name => {
    safe_cb(eid, () => { $(eid).text(_name) })
    if (cb) {
      cb(_name)
    }
  })
}

let unique_id = 0
let params

import '../stylesheets/app.css' // Import the page's CSS. Webpack will know what to do with it.
require('../help.md')
const crypto = require('crypto')
const buf = crypto.randomBytes(256).toString('hex')

// Import libraries we need.
import { default as Web3} from 'web3'
import { default as contract } from 'truffle-contract'
// import { default as clipboard } from 'clipboard';
// import clippy_img from '!!file!../images/clippy.svg'

import ERC20_artifacts from '../../build/contracts/ERC20.json'
let ERC20Contract = contract(ERC20_artifacts)

import twoKeyEconomy_artifacts from '../../build/contracts/TwoKeyEconomy.json'
let TwoKeyEconomy = contract(twoKeyEconomy_artifacts)
let TwoKeyEconomy_contractInstance

import TwoKeyReg_artifacts from '../../build/contracts/TwoKeyReg.json'
let TwoKeyReg = contract(TwoKeyReg_artifacts)
let TwoKeyReg_contractInstance

import TwoKeyContract_artifacts from '../../build/contracts/TwoKeyContract.json'
let TwoKeyContract = contract(TwoKeyContract_artifacts)
import TwoKeyAcquisitionContract_artifacts from '../../build/contracts/TwoKeyAcquisitionContract.json'
let TwoKeyAcquisitionContract = contract(TwoKeyAcquisitionContract_artifacts)
import TwoKeyPresellContract_artifacts from '../../build/contracts/TwoKeyPresellContract.json'
let TwoKeyPresellContract = contract(TwoKeyPresellContract_artifacts)

let twoKeyContractAddress
let from_twoKeyContractAddress
let from_twoKeyContractAddress_taken

function tbl_add_row (tbl, h) {
  let header_row = '<tr>' + h.join() + '</tr>'
  $(tbl).append(header_row)
}

let tbl_add_contract_active = {} // reset to {} every time we start a new table population
let population_count = 0  // increases every time we start a new table
function tbl_cleanup () {
  tbl_add_contract_active = {}
  population_count++
  $('#my-2key-contracts').empty()
  $('#my-2key-arcs').empty()
}

function tbl_add_contract (tbl, twoKeyContractAddress) {
  if (tbl_add_contract_active[tbl + twoKeyContractAddress]) {
    return
  }
  tbl_add_contract_active[tbl + twoKeyContractAddress] = true

  if (!$(tbl).children().length) {
    $(tbl).append("<tr><td colspan=\"6\" data-toggle='tooltip' title='what I have in the contract'>Me</td><td></td><td colspan=\"13\" data-toggle='tooltip' title='contract properties'>Contract</td></tr>")
    tbl_add_row(tbl, contract_header())
  }

  let row_callback = ((tbl, p) => {
    return (items) => {
      if (p == population_count) {
        tbl_add_row(tbl, items)
      }
    }
  })(tbl, population_count)

  getTwoKeyContract(twoKeyContractAddress, (TwoKeyContract_instance) => {
    contract_info(TwoKeyContract_instance, 0, row_callback)
  })
}

function init_TwoKeyReg () {
  if (TwoKeyReg_contractInstance.created) { return }

  TwoKeyReg_contractInstance.created = {}
  TwoKeyReg_contractInstance.joined = {}

  let my_address = whoAmI()
  TwoKeyReg_contractInstance.Created_event = TwoKeyReg_contractInstance.Created({owner: my_address}, {
    fromBlock: 'earliest',
    toBlock: 'pending'
  }, (error, log) => {
    if (active_created) {
      active_created--
      transaction_msg()
    } else {
      // old contracts I created in previous sessions will generate Created events
      // alert('unmatched create event')
    }
    if (!error) {
      check_event(TwoKeyReg_contractInstance, log)

      let twoKeyContractAddress = log.args.c
      TwoKeyReg_contractInstance.created[twoKeyContractAddress] = true

      // tbl_add_contract('#my-2key-contracts', twoKeyContractAddress)
      timer_cbs.push(populate)
    }
  })

  TwoKeyReg_contractInstance.Joined_event = TwoKeyReg_contractInstance.Joined({to: my_address}, {
    fromBlock: 'earliest',
    toBlock: 'pending'
  }, (error, log) => {
    if (active_joined) {
      active_joined--
      transaction_msg()
    }
    if (!error) {
      check_event(TwoKeyReg_contractInstance, log)

      let twoKeyContractAddress = log.args.c
      TwoKeyReg_contractInstance.joined[twoKeyContractAddress] = true

      // tbl_add_contract('#my-2key-arcs', twoKeyContractAddress)
      timer_cbs.push(populate)
    }
  })
}

function update_total_supply(address) {
  view(TwoKeyEconomy_contractInstance.totalSupply(address),
    (result) => {
      let totalSupply
      totalSupply = web3.fromWei(result.toString())

      view(TwoKeyEconomy_contractInstance.balanceOf(address),
        (result) => {
          $('#token-balance').html(web3.fromWei(result.toString()) + ' out of ' + totalSupply + ' tokens')
        }
      )
    }
  )
}

function init_TwoKeyEconomy () {
  let my_address = whoAmI()

  view(TwoKeyEconomy_contractInstance.owner(),
    (_owner) => {
      if (_owner == my_address) {
        $('#admin-alert').show()
      }
    }
  )

  update_total_supply(my_address)

  if (!TwoKeyEconomy_contractInstance.Transfer_event) {
    // run only once. However if init_TwoKeyEconomy will be called again with a new
    // my_address then the code below will be affected. which is what we want
    TwoKeyEconomy_contractInstance.Transfer_event = TwoKeyEconomy_contractInstance.Transfer({}, {
      // fromBlock: 'earliest',
      toBlock: 'pending'
    }, (error, log) => {
      if (!error) {
        check_event(TwoKeyEconomy_contractInstance, log)

        let from = log.args.from
        let to = log.args.to
        if (from == my_address || to == my_address) {
          update_total_supply(my_address)  // show the new amount of tokens the user has
        }

        // we may be transfering tokens to a presell contrac
        if (is_contract_displayed(from) || is_contract_displayed(to)) {
          populate()
        }
      }
    })
  }
}

// function cache (fn) {
//   let NO_RESULT = {} // unique, would use Symbol if ES2015-able
//   let res = NO_RESULT
//   return function () { // if ES2015, name the function the same as fn
//     if (res === NO_RESULT) return (res = fn.apply(this, arguments))
//     return res
//   }
// }

// cash all contracts
let contract_cache = {}
let contract_cache_cb = {}

function init_TwoKeyContract (TwoKeyContract_instance) {
  if (TwoKeyContract_instance.units) { return }

  TwoKeyContract_instance.given_to = {}
  TwoKeyContract_instance.units = {}

  // TwoKeyReg_contractInstance.Joined_event = TwoKeyReg_contractInstance.Joined({c: TwoKeyContract_instance.address}, {
  //   fromBlock: 'earliest',
  //   toBlock: 'latest'
  // }, (error, log) => {
  //
  TwoKeyContract_instance.Transfer_event = TwoKeyContract_instance.Transfer({}, {
    fromBlock: 'earliest',
    toBlock: 'pending'
  }, (error, log) => {
    if (!error) {
      transfer_event(TwoKeyContract_instance, log)
      timer_cbs.push(populate)
    }
  })

  // TwoKeyContract_instance.Transfer_event.get((error, logs) => {
  //     if (!error) {
  //         for (let i = 0; i < logs.length; i++) {
  //             transfer_event(TwoKeyContract_instance, logs[i]);
  //         }
  //     }
  // });

  TwoKeyContract_instance.Fulfilled_event = TwoKeyContract_instance.Fulfilled({}, {
    fromBlock: 'earliest',
    toBlock: 'pending'
  }, (error, log) => {
    if (active_fulfilled) {
      active_fulfilled--
      transaction_msg()
    }
    if (!error) {
      fulfilled_event(TwoKeyContract_instance, log)
      timer_cbs.push(populate)
    }
  })
  // TwoKeyContract_instance.Fulfilled_event.get((error, logs) => {
  //     if (!error) {
  //         for (let i = 0; i < logs.length; i++) {
  //             fulfilled_event(TwoKeyContract_instance, logs[i]);
  //         }
  //     }
  // });
  TwoKeyContract_instance.constantInfo = TwoKeyContract_instance.getConstantInfo()
  view(TwoKeyContract_instance.constantInfo,
      info => {
      TwoKeyContract_instance.info = {
        name: info[0],
        symbol: info[1],
        cost: info[2],
        bounty: info[3],
        quota: info[4],
        owner: info[5],
        ipfs_hash: info[6],
        unit_decimals: info[7]
      }
    }
  )
}

function getTwoKeyContract (address, cb) {
  let contract = contract_cache[address]
  if (contract) {
    cb(contract)
  } else {
    if (contract_cache_cb[address]) {
      contract_cache_cb[address].push(cb)
    } else {
      contract_cache_cb[address] = [cb]
      view(TwoKeyContract.at(address),
        contract => {
          init_TwoKeyContract(contract)
          contract_cache[address] = contract
          while (contract_cache_cb[address] && contract_cache_cb[address].length) {
            cb = contract_cache_cb[address].pop()
            cb(contract)
          }
          contract_cache_cb[address] = null
        }
      )
    }
  }
}

// We are using IPFS to store content for each product.
// The web site also contains an IPFS node and this App connects to it
const ipfsAPI = require('ipfs-api')
let ipfs = ipfsAPI(window.document.location.hostname, '5001')

String.prototype.hashCode = function () {
  let hash = 0, i, chr
  if (this.length === 0) return hash
  for (i = 0; i < this.length; i++) {
    chr = this.charCodeAt(i)
    hash = ((hash << 5) - hash) + chr
    hash |= 0 // Convert to 32bit integer
  }
  return hash
}

let stop_checking = 0
function check_user_change () {
  if (stop_checking == 0) {
    _whoAmI()
  }
}

function whoAmI (doing_login) {
  // disable timer calling whoAmi (when using metamask)
  stop_checking++
  let my_address = _whoAmI(doing_login)
  // enable timer calling whoAmi (when using metamask)
  stop_checking--
  return my_address
}

let last_address
let no_warning

function username2address (username, cb, cberror) {
  if (username === 'coinbase') {
    cb(web3.eth.coinbase)
  } else if (username.startsWith('0x')) {
    cb(username)
  } else {
    view(TwoKeyReg_contractInstance.getName2Owner(username),
      address => {
        if (address && address != '0x0000000000000000000000000000000000000000') {
          cb(address)
        } else {
          alert('user ' + username + ' is not signed-up')
          if (cberror) {
            cberror()
          }
        }
      }
    )
  }
}

function _whoAmI (doing_login) {
  if (!doing_login) {
    $("#login-user-data").hide()
  }

  let accounts = web3.eth.accounts
  if (!accounts || accounts.length == 0) {
    if (!no_warning) {
      no_warning = true
      if (localStorage.meta_mask) {
        alert("it looks as if your MetaMask account is locked. Please unlock it and select an account")
      } else {
        alert("Something is wrong in testrpc/ganauche configuration.")
      }
    }
    if (last_address) {
      logout()
      if (localStorage.meta_mask) {
        $('#metamask-login').show()
      }
      $('.login').hide()
      last_address = null
    }
    return
  }

  let my_address
  let username = localStorage.username
  if (username) {
    if (username === 'coinbase') {
      my_address = web3.eth.coinbase
    } else if (username.startsWith('0x')) {
      my_address = username
    } else {
      let n = accounts.length
      my_address = accounts[username.hashCode() % n]
    }
  } else {
    // can happen when using metamask
    if (accounts.length == 1) {
      my_address = accounts[0]
    }
  }
  let last = last_address
  last_address = my_address
  if (!my_address) {
    logout()
    return
  }

  if (last && last != my_address) {
    // for example user changed his account on MetaMask
    alert('User account has changed.')
    // user_changed()
    location.reload()
    username = null
  }

  if (my_address && last != my_address) {
    // check consistancy
    view(TwoKeyReg_contractInstance.getOwner2Name(my_address),
      _name => {
        if (_name) {
          if (!username) {
            localStorage.username = _name
          }
          if (!username || (username === _name)) {
            lookupUserInfo()
          } else {
            alert('Sorry, demo name already in use, try a different one')
            logout()
          }
        } else {
          if (username) {
            if (doing_login) {
              let ok = confirm('Signup on 2Key central contract?')
              if (ok) {
                // if addName will end succussefully then call lookupUserInfo
                transaction_start(
                  TwoKeyReg_contractInstance.addName(username, {
                    gas: gastimate(80000),
                    from: my_address
                  }),
                  () => timer_cbs.push(lookupUserInfo)
                )
              }
            } else {
              logout()
            }
          } else {
            logout()
            $("#login-user-data").show()
            $('#login-user-address').html(my_address.toString())
            web3.eth.getBalance(my_address, function (error, result) {
              $('#login-user-balance').html(web3.fromWei(result.toString()) + ' ETH')
            })
          }
        }
      }
    )
  }

  return my_address
}

window.login = function () {
  let username = $('#login-user-name').val()
  if (username.length < 3) {
    tempAlert('Name to short', 2000)
    return
  }
  // $("#user-name").html(username);
  localStorage.username = username
  last_address = null
  whoAmI(true)
}

function clean_user () {
  $('#admin-alert').hide()
  $('#user-name').html('')
  $('#user-balance').html('')
  $('#token-balance').html('')
  $('#token-destination').val('')
  $('#token-amount').val('')
}

function user_changed () {
  delete localStorage.username

  clean_user()
  $('#contract-table').empty()
  $('#buy').removeAttr('onclick')
  $('#redeme').removeAttr('onclick')

  d3_reset()

  TwoKeyReg_contractInstance.created = null
  TwoKeyReg_contractInstance.joined = null

  tbl_cleanup()
}

function logout () {
  user_changed()

  new_user()
  $('#login-user-name').val('')
  $('.login').show()

}

window.logout = function () {
  twoKeyContractAddress = null
  from_twoKeyContractAddress = null
  from_twoKeyContractAddress_taken = null
  logout()
  history.pushState(null, '', location.href.split('?')[0])
}

window.home = function () {
  twoKeyContractAddress = null
  d3_reset()
  history.pushState(null, '', location.href.split('?')[0])
  product_cleanup()
  populate()
}

window.jump_to_contract_page = function (address) {
  twoKeyContractAddress = address
  history.pushState(null, '', location.href.split('?')[0])
  populate()
}

// window.getETH = function () {
//   let my_address = whoAmI()
//   TwoKeyReg_contractInstance.fundtransfer(my_address, web3.toWei(1.0, 'ether'),
//     {gas: 3000000, from: my_address}).then(function () {
//   }).catch(function (e) {
//     alert(e)
//   })
// }
//
// window.giveETH = function () {
//   let my_address = whoAmI()
//   web3.eth.sendTransaction({from: my_address, to: TwoKeyReg.address, value: web3.toWei(1, 'ether')})
// }

window.buy = function (twoKeyContractAddress, name, cost) {
  let my_address = whoAmI()
  let units = prompt('you are about to fulfill (buy) the product "' + name + '" from contract \n' + twoKeyContractAddress +
      '\nfor ' + cost + ' ETH per unit. Please enter the number of units you want to buy (0 to cancel)', '1');
  if (units && units != "0") {
    units = parseFloat(units)
    getTwoKeyContract(twoKeyContractAddress, (TwoKeyContract_instance) => {
      if (from_twoKeyContractAddress) {
        // if the transaction will end succussefully then call updateUserInfo
        active_fulfilled++
        transaction_start(
          TwoKeyContract_instance.buyFrom(
            from_twoKeyContractAddress,
            {
              gas: gastimate(240000),
              from: my_address,
              value: web3.toWei(units*cost, 'ether')
          }),
          () => {
            transaction_msg()
            updateUserInfo
          },
          () => {
            active_fulfilled--
            transaction_msg()
          }
        )
      } else {
        // if the transaction will end succussefully then call updateUserInfo
        active_fulfilled++
        transaction_start(
          TwoKeyContract_instance.buyProduct(
            {
              gas: gastimate(240000),
              from: my_address,
              value: web3.toWei(units*cost, 'ether')
          }),
          () => {
            transaction_msg()
            updateUserInfo
          },
          () => {
            active_fulfilled--
            transaction_msg()
          }
        )
      }
    })
  }
}

window.redeem = function (twoKeyContractAddress) {
  let ok = confirm('you are about to redeem the balance of 2Key contract \n' + twoKeyContractAddress)
  if (ok) {
    let my_address = whoAmI()
    getTwoKeyContract(twoKeyContractAddress, (TwoKeyContract_instance) => {
      // if the transaction will end succussefully then call updateUserInfo and populate
      transaction_start(
        TwoKeyContract_instance.redeem({gas: gastimate(140000), from: my_address}),
        () => {
          updateUserInfo()
          timer_cbs.push(populate)
        }
        )
    })
  }
}

function tempAlert (msg, duration) {
  bootbox.alert(msg, function () {
    console.log('Alert Callback')
  })
  window.setTimeout(function () {
    bootbox.hideAll()
  }, duration)
}

// https://www.sitepoint.com/get-url-parameters-with-javascript/
function getAllUrlParams (url) {
  // get query string from url (optional) or window
  let queryString = url ? url.split('?')[1] : window.location.search.slice(1)

  // we'll store the parameters here
  let obj = {}

  // if query string exists
  if (queryString) {
    // stuff after # is not part of query string, so get rid of it
    queryString = queryString.split('#')[0]

    // split our query string into its component parts
    let arr = queryString.split('&')

    for (let i = 0; i < arr.length; i++) {
      // separate the keys and the values
      let a = arr[i].split('=')

      // in case params look like: list[]=thing1&list[]=thing2
      let paramNum = undefined
      let paramName = a[0].replace(/\[\d*\]/, function (v) {
        paramNum = v.slice(1, -1)
        return ''
      })

      // set parameter value (use 'true' if empty)
      let paramValue = typeof (a[1]) === 'undefined' ? true : a[1]

      // (optional) keep case consistent
      paramName = paramName.toLowerCase()
      paramValue = paramValue.toLowerCase()

      // if parameter name already exists
      if (obj[paramName]) {
        // convert value to array (if still string)
        if (typeof obj[paramName] === 'string') {
          obj[paramName] = [obj[paramName]]
        }
        // if no array index number specified...
        if (typeof paramNum === 'undefined') {
          // put the value on the end of the array
          obj[paramName].push(paramValue)
        }
        // if array index number specified...
        else {
          // put the value at that index number
          obj[paramName][paramNum] = paramValue
        }
      }
      // if param name doesn't exist yet, set it
      else {
        obj[paramName] = paramValue
      }
    }
  }

  return obj
}

// window.paste_address = function (elm) {
//   let t = elm.innerHTML
//   $('#influence-address').val(t)
//   $('#buy-address').val(t)
// }

// window.copy_link = function (twoKeyContractAddress, my_address) {
//   let link = location.origin + '/?c=' + twoKeyContractAddress + '&f=' + my_address
//   alert(link)
// }

function product_cleanup () {
  // hide the product create-contract box
  $('#erc20-address').val('')
  $('#product-name').val('')
  $('#product-symbol').val('')
  $('#total-arcs').val('')
  $('#quota').val('')
  $('#cost').val('')
  $('#total-units').val('')
  $('#bounty').val('')
  $('#bounty-tokens').val('')
  $("#expiration").val("");
  $('#description').val('')
  $('#add-contract').show()
  $('#create-contract').hide()
}

// // https://mostafa-samir.github.io/async-iterative-patterns-pt1/
// function IterateOver (list, iterator, callback) {
//   // this is the function that will start all the jobs
//   // list is the collections of item we want to iterate over
//   // iterator is a function representing the job when want done on each item
//   // callback is the function we want to call when all iterations are over
//
//   let doneCount = 0 // here we'll keep track of how many reports we've got
//
//   function report () {
//     // this function resembles the phone number in the analogy above
//     // given to each call of the iterator so it can report its completion
//
//     doneCount++
//
//     // if doneCount equals the number of items in list, then we're done
//     if (doneCount === list.length) { callback() }
//   }
//
//   // here we give each iteration its job
//   list.forEach(item => iterator(item, report))
//   // for(let i = 0; i < list.length; i++) {
//   //     // iterator takes 2 arguments, an item to work on and report function
//   //     iterator(list[i], report)
//   // }
// }

let MAX_DEPTH = 1000

function bdfs (TwoKeyContract_instance, start_address, cb) {
  let nodes = [start_address]
  let depth = 0
  while (nodes.length && depth < MAX_DEPTH) {
    let new_nodes = []
    for (let i = 0; i < nodes.length; i++) {
      let address = nodes[i]
      if (cb(address, depth)) {
        return
      }
      let given_to = TwoKeyContract_instance.given_to
      if (given_to) { given_to = given_to[address] }
      if (given_to) { new_nodes = new_nodes.concat(given_to) }
    }
    if (!new_nodes) {
      break
    }
    nodes = new_nodes
    depth++
  }
  cb(0, depth)
}

function my_depth (TwoKeyContract_instance, owner, my_address) {
  let final_depth
  function cb (address, depth) {
    if (address == my_address) {
      final_depth = depth
      return true // break
    } else if (address == 0) {
      final_depth = MAX_DEPTH
      return true // break
    } else {
      return false // dont break
    }
  }
  bdfs(TwoKeyContract_instance, owner, cb)
  return final_depth
}

function get_kpis (TwoKeyContract_instance, my_address, owner) {
  let depth_sum = 0
  let conversions = 0
  let influencers = 0
  let span = 0
  function cb (address, depth) {
    if (TwoKeyContract_instance.units[address]) {
      conversions++
      depth_sum += depth
    }
    let to = TwoKeyContract_instance.given_to[address]
    if (to && to.length) {
      influencers++
      span += to.length
    }
    return false // dont break
  }
  bdfs(TwoKeyContract_instance, my_address, cb)
  let avg_depth = 'NA'
  if (conversions) {
    avg_depth = depth_sum / conversions
  }
  let avg_span = 'NA'
  if (influencers) {
    avg_span = span / influencers
  }
  // remove contract creator as influencer
  if (influencers && my_address == owner) { influencers-- }
  return [conversions, avg_depth, influencers, avg_span]
}

function contract_header () {
  let items = []
  items.push("<td data-toggle='tooltip' title='the roll I am having in this contract'>Roll</td>")
  items.push("<td data-toggle='tooltip' title='number of ARCs I have in the contracts'>my ARCs balance</td>")
  items.push("<td data-toggle='tooltip' title='key link'>my 2key link</td>")
  items.push("<td data-toggle='tooltip' title='Number of units I bought'>&#35;units bought</td>")
  items.push("<td data-toggle='tooltip' title='ETH I have in the contract. click to redeem'>total earning (ETH)</td>")
  items.push("<td data-toggle='tooltip' title='estimated reward'>est. reward per conversion unit</td>")

  items.push('<td></td>')

  items.push("<td data-toggle='tooltip' title='contract/product name'>name</td>")
  items.push("<td data-toggle='tooltip' title='contract symbol'>ARC symbol</td>")
  items.push("<td data-toggle='tooltip' title='who created the contract'>owner</td>")
  items.push("<td data-toggle='tooltip' title='how many ARCs an influencer or a customer will receive when opening a 2Key link of this contract'>default share quota per influencer</td>")
  items.push("<td data-toggle='tooltip' title='cost of joining'>price to join</td>")
  items.push("<td data-toggle='tooltip' title='number of units being sold'>units offered</td>")
  items.push("<td data-toggle='tooltip' title='product description'>unit description</td>")
  items.push("<td data-toggle='tooltip' title='cost of buying the product sold in the contract. click to buy'>price per unit</td>")
  items.push("<td data-toggle='tooltip' title='total amount that will be taken from the cost and be distributed between influencers'>max reward per unit (ETH)</td>")
  items.push("<td data-toggle='tooltip' title='total balance of ETH deposited in contract'>gross income (ETH)</td>")
  items.push("<td data-toggle='tooltip' title='total number of ARCs in the contract'>total ARCs generated</td>")
  items.push("<td data-toggle='tooltip' title='KPIs'>&#35;converters, avg. depth to converter, &#35;influencers, avg. &#35;child-influencers</td>")
  items.push("<td data-toggle='tooltip' title='the address of the contract'>address</td>")

  return items
}

function contract_info (TwoKeyContract_instance, min_arcs, callback) {
  let items = []
  let my_address = whoAmI()
  let twoKeyContractAddress = TwoKeyContract_instance.address
  let take_link = location.origin + '/?c=' + twoKeyContractAddress + '&f=' + my_address
  // let contract_link = "./?c=" + twoKeyContractAddress;
  let onclick_name = "jump_to_contract_page('" + twoKeyContractAddress + "')"
  view(TwoKeyContract_instance.constantInfo,
    constant_info => {
      let name, symbol, cost, bounty, quota, owner, ipfs_hash, unit_decimals;
      [name, symbol, cost, bounty, quota, owner, ipfs_hash, unit_decimals] = constant_info
      view(TwoKeyContract_instance.getDynamicInfo(my_address),
        info => {
          let arcs, units, xbalance, total_arcs, balance, total_units;
          [arcs, units, xbalance, total_arcs, balance, total_units] = info

          balance = web3.fromWei(balance)
          xbalance = web3.fromWei(xbalance)
          cost = web3.fromWei(cost.toString())
          bounty = web3.fromWei(bounty.toString())
          units = units.toNumber()
          arcs = arcs.toNumber()
          unit_decimals = unit_decimals.toNumber()

          let onclick_buy = "buy('" + twoKeyContractAddress + "','" + name + "'," + cost + ')'
          let onclick_redeem = "redeem('" + twoKeyContractAddress + "')"
          $('#buy').attr('onclick', onclick_buy)
          $('#redeem').attr('onclick', onclick_redeem)

          if ((arcs >= min_arcs) || (xbalance > 0)) {
            if (arcs >= BIG_INT) {
              arcs = '&infin;'
            }
            if (total_arcs >= BIG_INT) {
              total_arcs = '&infin;'
            }
            if (quota >= BIG_INT) {
              quota = '&infin;'
            }

            {
              let roll
              if (owner == my_address) {
                roll = 'Contractor'
              } else if (units) {
                roll = 'Converter'
              } else if (TwoKeyReg_contractInstance.joined[twoKeyContractAddress] || arcs) {
                roll = 'Influencer'
              } else {
                roll = ''
              }
              items.push('<td>' + roll + '</td>')
            }

            items.push('<td>' + arcs + '</td>')
            unique_id = unique_id + 1
            short_url(take_link, '#id' + unique_id)
            items.push('<td>' +
                    "<button class='lnk0 bt' id=\"id" + unique_id + '" ' +
                    "data-toggle='tooltip' title='copy to clipboard a 2Key link for this contract'" +
                    "msg='2Key link was copied to clipboard. Someone else opening it will take one ARC from you'" +
                    'data-clipboard-text="' + take_link + '">' + take_link +
                    '</button></td>')
            units = units / 10.**unit_decimals
            items.push('<td>' + units + '</td>')
            items.push('<td>' +
                    "<button class='bt' onclick=\"" + onclick_redeem + '"' +
                    "data-toggle='tooltip' title='redeem'" +
                    '">' + xbalance +
                    '</button></td>')

            unique_id = unique_id + 1
            let tag_est_reward = 'id' + unique_id
            items.push('<td id="' + tag_est_reward + '" ></td>')
            let depth = my_depth(TwoKeyContract_instance, owner, my_address)
            let est_reward = ''
            if (depth == MAX_DEPTH || depth == 0) {
              est_reward = 'NA'
            } else {
              est_reward = '' + parseFloat(bounty) / depth
            }
            safe_cb('#' + tag_est_reward, () => {
              $('#' + tag_est_reward).text(est_reward)
            })

            // separator between my part and contract part
            items.push('<td></td>')

            items.push('<td>' +
                    "<button class='bt' onclick=\"" + onclick_name + '"' +
                    "data-toggle='tooltip' title='jump to contract page'" +
                    '">' + name +
                    '</button></td>')
            // items.push("<td><a href='" + contract_link + "'>"+ name + "</a></td>");
            items.push('<td>' + symbol + '</td>')
            {
              unique_id = unique_id + 1
              let tag_owner = 'id' + unique_id
              items.push('<td id="' + tag_owner + '" >' + owner + '</td>')
              owner2name(owner, '#' + tag_owner)
            }

            items.push('<td>' + quota + '</td>')
            let join_cost = 0
            items.push('<td>' + join_cost + '</td>')

            total_units = total_units / 10.**unit_decimals
            items.push('<td>' + total_units + '</td>')
            {
              unique_id = unique_id + 1
              let tag_description = 'id' + unique_id
              items.push('<td id="' + tag_description + '" >' + ipfs_hash + '</td>')
              if (ipfs_hash) {
                ipfs.cat(ipfs_hash, (err, res) => {
                  if (err) throw err
                  safe_cb('#' + tag_description, () => {
                    $('#' + tag_description).text(res.toString())
                  })
                })
              }
            }

            items.push('<td>' +
                    "<button class='bt' onclick=\"" + onclick_buy + '"' +
                    "data-toggle='tooltip' title='buy'" +
                    '">' + cost +
                    '</button></td>')

            items.push('<td>' + bounty + '</td>')

            items.push('<td>' + balance + '</td>')
            items.push('<td>' + total_arcs + '</td>')

            let kpis = get_kpis(TwoKeyContract_instance, owner, owner)
            items.push('<td>' + kpis.join('/') + '</td>')

            items.push('<td>' +
                    "<button class='lnk bt' " +
                    "data-toggle='tooltip' title='copy to clipboard' " +
                    "msg='contract address was copied to clipboard'>" +
                    twoKeyContractAddress + '</button>' +
                    '</td>')
          }
          callback(items, constant_info, info)
        }
      )
    }
  )
}

function populateMy2KeyContracts () {
  tbl_cleanup()
  if (!TwoKeyReg_contractInstance.created) {
    return
  }

  let tbl = '#my-2key-contracts'
  for (let c in TwoKeyReg_contractInstance.created) {
    tbl_add_contract(tbl, c)
  }

  tbl = '#my-2key-arcs'
  for (let c in TwoKeyReg_contractInstance.joined) {
    tbl_add_contract(tbl, c)
  }
}

function populateContract () {
  $('#join-btn').hide()
  $('#buy').hide()
  $('#redeem').hide()

  $('#contract-table').empty()
  let h = contract_header()
  function contract_callback (c, constant_info, info) {
    for (let i = 0; i < h.length; i++) {
      let row = '<tr>' + h[i] + c[i] + '</tr>'
      $('#contract-table').append(row)
    }

    let name, symbol, cost, bounty, quota, total_units, owner, ipfs_hash;
    [name, symbol, cost, bounty, quota, total_units, owner, ipfs_hash] = constant_info
    let arcs, units, xbalance, total_arcs, balance;
    [arcs, units, xbalance, total_arcs, balance] = info

    bounty = web3.fromWei(bounty.toString())
    $('#summary-quota').text(quota)
    $('#summary-reward').text(bounty)

    // show buttons only if contract info is ready
    $('#buy').show()
    // show redeem button only if there is balance
    if (xbalance.toNumber()) {
      $('#redeem').show()
    }

    if (from_twoKeyContractAddress) {
      // show join button only if the user does not already have ARCs (units)
      if (arcs.toNumber() == 0) {
        // // on first time contract_take is called a pop up will ask you
        // // if you want to take
        // if (from_twoKeyContractAddress != from_twoKeyContractAddress_taken) {
        //   from_twoKeyContractAddress_taken = from_twoKeyContractAddress
        //   window.contract_take()
        // }
        // the pop up is modal so is it ok to show buttons
        $('#join-btn').show()
      }
    }
  }
  getTwoKeyContract(twoKeyContractAddress, (TwoKeyContract_instance) => {
    contract_info(TwoKeyContract_instance, -1, contract_callback)
    d3_init()
  })
}

let populate_running = false
function populate () {
  // guard againset reentrance
  if (populate_running) {
    console.log('reentrant')
    return
  }
  populate_running = true

  if (twoKeyContractAddress) {
    $('.contract').show()
    $('.contracts').hide()
    populateContract()
  } else {
    $('.contracts').show()
    $('.contract').hide()
    $('#buy').removeAttr('onclick')
    $('#redeme').removeAttr('onclick')
    populateMy2KeyContracts()
  }

  populate_running = false
}

function is_contract_displayed(contract) {
  if (twoKeyContractAddress) {
    return twoKeyContractAddress == contract
  }

  for (let c in TwoKeyReg_contractInstance.created) {
    if (c == contract) {
      return true
    }
  }

  for (let c in TwoKeyReg_contractInstance.joined) {
    if (c == contract) {
      return true
    }
  }

  return false
}

// window.giveARCs = function () {
//   let twoKeyContractAddress = $('#influence-address').val()
//   let target = $('#target-address').val()
//   if (!target || !twoKeyContractAddress) {
//     alert('specify contract and target user')
//     return
//   }
//
//   let my_address = whoAmI()
//   getTwoKeyContract(twoKeyContractAddress, (TwoKeyContract_instance) => {
//     TwoKeyContract_instance.transfer(target, 1, {gas: 1400000, from: my_address}).then((tx) => {
//       console.log(tx)
//       $('#target-address').val('')
//       $('#influence-address').val('')
//       populate()
//     }).catch(function (e) {
//       alert(e)
//     })
//   })
// }

window.contract_take = function () {
  if (!from_twoKeyContractAddress) {
    return
  }

  let my_address = whoAmI()
  if (from_twoKeyContractAddress == my_address) {
    safe_alert("You can't take your own ARCs. Switch to a different user and try again.")
    return
  }
  getTwoKeyContract(twoKeyContractAddress, (TwoKeyContract_instance) => {
    view(TwoKeyContract_instance.quota(),
      quota => {
        let ok = confirm('you are about to take 1 ARC from user\n' + from_twoKeyContractAddress +
                '\nin contract\n' + twoKeyContractAddress +
                '\nand this will turn into ' + quota + ' ARCs in your account')
        if (ok) {
          let my_address = whoAmI()
          // if transaction end successfully clean url
          // if it fails clean url and send an alert
          active_joined++
          transaction_start(
            TwoKeyContract_instance.transferFrom(from_twoKeyContractAddress, my_address, 1, {
              gas: gastimate(140000),
              from: my_address
            }),
            () => {
              transaction_msg()
              history.pushState(null, '', location.href.split('?')[0])
            },
            () => {
              active_joined--
              // clean the URL appearing in the address bar
              history.pushState(null, '', location.href.split('?')[0])
              transaction_msg()
            }
          )
        }
      }
    )
  })
}

function addContract () {
  whoAmI()  // check the address did not change
  $('#add-contract').hide()
  $('#create-contract').show()
}

window.addAquistionContract = function () {
  $('.aquistion').show()
  $('.presell').hide()
  addContract()
}

window.addPresellContract = function () {
  $('.aquistion').hide()
  $('.presell').show()
  addContract()
}


window.cancelContract = function () {
  product_cleanup()
}

window.createContract = function () {
  let erc20_address = $('#erc20-address').val()
  let name = $('#product-name').val()
  let symbol = $('#product-symbol').val()
  if ($('#erc20-address').is(":visible")) { // TODO better way to decide which type of contract we are creating
    if (!erc20_address) {
      erc20_address = TwoKeyEconomy_contractInstance.address
    }
    createContract(name, symbol, erc20_address)
  } else {
    createContract(name, symbol)
  }
}

function createContract (name, symbol, erc20_address) {
  if (!erc20_address) {
    erc20_address = 0
  }
  let total_arcs = $('#total-arcs').val()
  if (total_arcs) {
    total_arcs = parseInt(total_arcs)
  } else {
    total_arcs = BIG_INT
  }
  let quota = $('#quota').val()
  if (quota) {
    quota = parseInt(quota)
  } else {
    quota = BIG_INT
  }
  let cost = $('#cost').val()
  if (!cost) {
    cost = 0
  }
  let total_units = $('#total-units').val()
  if (!total_units) {
    total_units = 0
  }
  let bounty = $('#bounty').val()
  if (!bounty) {
    bounty = 0
  }
  let bounty_tokens = $('#bounty-tokens').val()
  if (!bounty_tokens) {
    bounty_tokens = 0
  }
  let productExpiration = $('#product-expiration').val()
  let description = $('#description').val()

  product_cleanup()

  function cb(ipfs_hash) {
    let address = whoAmI()
    // value: web3.toWei(0.001, 'ether'),
    let trn
    if (erc20_address) {
      trn = TwoKeyPresellContract.new(TwoKeyReg_contractInstance.address, name, symbol, total_arcs, quota,
        web3.toWei(parseFloat(cost), 'ether'), web3.toWei(parseFloat(bounty), 'ether'),
        ipfs_hash, erc20_address,
        {gas: gastimate(4000000), from: address})
    } else {
      trn = TwoKeyAcquisitionContract.new(TwoKeyReg_contractInstance.address,
        name, symbol, total_arcs, quota,
        web3.toWei(parseFloat(cost), 'ether'), web3.toWei(parseFloat(bounty), 'ether'),
        parseInt(total_units), ipfs_hash,
        {gas: gastimate(4000000), from: address})
    }
    active_created++
    transaction_start(trn, () => {
      transaction_msg()
    }, () => {
      active_created--
      transaction_msg()
    })
  }

  if (description) {
    ipfs.add([Buffer.from(description)], (err, res) => {
      if (err) {
        alert(err)
        throw err
      }
      const ipfs_hash = res[0].hash
      cb(ipfs_hash)
    })
  } else {
    cb('')
  }
}

function update_user_balance(my_address) {
  if (!my_address) {
    my_address = whoAmI()
  }

  if (my_address) {
    web3.eth.getBalance(my_address, function (error, result) {
      if (!error) {
        $('#user-balance').html(web3.fromWei(result.toString()) + ' ETH')
      }
    })
  }
}

function updateUserInfo () {
  clean_user()
  let username = localStorage.username
  $('#user-name').html(username)
  let my_address = whoAmI()
  if (!my_address) {
    alert('Unlock MetaMask and reload page')
  } else {
    $('#user-address').html(my_address.toString())
    update_user_balance(my_address)
    update_total_supply(my_address)
  }
}

window.transferTokens = function () {
  let destination = $('#token-destination').val()
  username2address(destination, (_destination) => {
    let myaddress = whoAmI()
    let amount = parseFloat($('#token-amount').val())
    amount = web3.toWei(amount, 'ether') // TODO use the decimals value of the TwoKeyEconomy contract

    transaction_start(
      TwoKeyEconomy_contractInstance.transfer(
        _destination, amount,
        {
          gas: gastimate(140000),
          from: myaddress,
      }),
      () => {
        tempAlert('OK', 1000)
      }
    )
  })
}

window.transferFromTokens = function () {
  let destination = $('#token-destination').val()
  username2address(destination, (_destination) => {
    let myaddress = whoAmI()
    let amount = parseFloat($('#token-amount').val())
    amount = web3.toWei(amount, 'ether') // TODO use the decimals value of the TwoKeyEconomy contract

    transaction_start(
      TwoKeyEconomy_contractInstance.transferFrom(
        _destination, myaddress, amount,
        {
          gas: gastimate(140000),
          from: myaddress,
      }),
      () => {
        tempAlert('OK', 1000)
        updateUserInfo()
      }
    )
  })
}

window.approveTokens = function () {
  let destination = $('#token-destination').val()
  username2address(destination, (_destination) => {
    let myaddress = whoAmI()
    let amount = parseFloat($('#token-amount').val())
    amount = web3.toWei(amount, 'ether') // TODO use the decimals value of the TwoKeyEconomy contract

    transaction_start(
      TwoKeyEconomy_contractInstance.approve(
        _destination, amount,
        {
          gas: gastimate(140000),
          from: myaddress,
      }),
      () => {
        tempAlert('OK', 1000)
      }
    )
  })
}

window.allowanceTokens = function () {
  let destination = $('#token-destination').val()
  username2address(destination, (_destination) => {
    let myaddress = whoAmI()

    view(TwoKeyEconomy_contractInstance.allowance(_destination,myaddress),
      (result) => {
        let amount = web3.fromWei(result.toString()) // TODO use the decimals value of the TwoKeyEconomy contract
        $('#token-amount').val(amount)
      }
    )
  })
}

function lookupUserInfo () {
  updateUserInfo()
  init_TwoKeyReg()
  init_TwoKeyEconomy()
  populate()
  new_user()
  $('.logout').show()
}

function ipfs_init () {
  ipfs.id((err, res) => {
    if (err) throw err
    console.log(res.id)
    console.log(res.agentVersion)
    console.log(res.protocolVersion)
  })
}

function check_event (c, e) {
  // allow events from a transactionHash to be used only once
  if (!c.transactionHash) {
    c.transactionHash = {}
  }

  // add event nonce because ganache bug sometimes reuse transactionHash
  let h = e.transactionHash
  if (c.transactionHash[h]) {
    console.log('Collision on transactionHash ' + h)
    // alert('Collision on transactionHash ' + h)
    // return false
  }
  c.transactionHash[h] = true

  return true
}

function transfer_event (c, e) {
  if (!check_event(c, e)) {
    return
  }
  // e.address;
  let from = e.args.from
  let to = e.args.to

  if (!c.given_to[from]) {
    c.given_to[from] = []
  }
  c.given_to[from].push(to)
}

function fulfilled_event (c, e) {
  if (!check_event(c, e)) {
    return
  }
  // e.address;
  let to = e.args.to
  let units = e.args.units

  c.units[to] = units
}

function init () {
  params = getAllUrlParams()
  twoKeyContractAddress = params.c
  from_twoKeyContractAddress = params.f
  if (twoKeyContractAddress) {
    $('#join-btn').hide()
    $('#buy').hide()
    $('#redeem').hide()
    $('.contract').show()
    $('.contracts').hide()
  } else {
    $('.contracts').show()
    $('.contract').hide()
    $('#buy').removeAttr('onclick')
    $('#redeme').removeAttr('onclick')
  }
  product_cleanup()

  TwoKeyEconomy.setProvider(web3.currentProvider)
  TwoKeyReg.setProvider(web3.currentProvider)

  TwoKeyContract.setProvider(web3.currentProvider)
  TwoKeyAcquisitionContract.setProvider(web3.currentProvider)
  TwoKeyPresellContract.setProvider(web3.currentProvider)
  ERC20Contract.setProvider(web3.currentProvider)

  ipfs_init()

  setInterval(() => {
    while (timer_cbs_delayed.length) {
      let cb = timer_cbs_delayed.pop()
      cb()
    }

    // remove dups
    timer_cbs_delayed = [];
    $.each(timer_cbs, function(i, el){
        if($.inArray(el, timer_cbs_delayed) === -1) timer_cbs_delayed.push(el);
    });

    timer_cbs = []
  }, 300)


  /* TwoKeyReg.deployed() returns an instance of the contract. Every call
   * in Truffle returns a promise which is why we have used then()
   * everywhere we have a transaction call
   */
  view(TwoKeyEconomy.deployed(), contractInstance => {
    TwoKeyEconomy_contractInstance = contractInstance
    view(TwoKeyReg.deployed(), contractInstance => {
      TwoKeyReg_contractInstance = contractInstance
      // init_TwoKeyReg();
      $('#loading').hide()
      whoAmI()
    })
  })
}

function new_user () {
  d3_reset()
  $('.login').hide()
  $('.logout').hide()
  $('#metamask-login').hide()
}

$(document).ready(function () {
  $('#loading').show()
  new_user()

  // https://clipboardjs.com/
  let clipboard_lnk0 = new Clipboard('.lnk0')

  clipboard_lnk0.on('success', function (e) {
    console.info('Action:', e.action)
    console.info('Text:', e.text)
    console.info('Trigger:', e.trigger)
    let msg = e.trigger.getAttribute('msg')
    tempAlert(msg, 3000)
    e.clearSelection()
  })

  clipboard_lnk0.on('error', function (e) {
    console.error('Action:', e.action)
    console.error('Trigger:', e.trigger)
  })
  let clipboard_lnk = new Clipboard('.lnk',
    {
      text: function (trigger) {
        return trigger.innerHTML
      }
    }
  )
  clipboard_lnk.on('success', function (e) {
    console.info('Action:', e.action)
    console.info('Text:', e.text)
    console.info('Trigger:', e.trigger)
    let msg = e.trigger.getAttribute('msg')
    tempAlert(msg, 2200)
    e.clearSelection()
  })

  clipboard_lnk.on('error', function (e) {
    console.error('Action:', e.action)
    console.error('Trigger:', e.trigger)
  })

  let url = 'http://' + window.document.location.hostname + ':8545'

  if (typeof web3 !== 'undefined') {
    // Use Mist/MetaMask's provider
    $('#metamask-login').text('Make sure MetaMask is configured to use the test network ' + url)

    $('#metamask-login').show()
    $('#logout-button').hide()
    // if (!localStorage.meta_mask) {
    //   // could happen if previous time we run the MetaMask extension was not installed/disabled
    //   delete localStorage.username
    // }
    // When using meta-mask, the extension gives us the address and we retrieve the user name
    // so dont use stored user name from previous session
    delete localStorage.username
    localStorage.meta_mask = true

    console.warn('Using web3 detected from external source like Metamask')
    window.web3 = new Web3(web3.currentProvider)
    web3.version.getNetwork((err, netId) => {
      let ok = false
      switch (netId) {
        case '1':
          console.log('This is mainnet')
          break
        case '2':
          console.log('This is the deprecated Morden test network.')
          break
        case '3':
          console.log('This is the ropsten test network.')
          break
        case '4':
          console.log('This is the Rinkeby test network.')
          break
        case '42':
          console.log('This is the Kovan test network.')
          break
        default:
          console.log('This is an unknown network.')
          ok = true
      }
      if (!ok) {
        alert('Configure MetaMask to work on the following network ' + url)
        return
      }

      // with meta-mask it is possible for the user to switch account without
      // us knowing about it
      setInterval(check_user_change, 500)
    })
  } else {
    // not using MetaMask

    if (localStorage.meta_mask) {
      // the MetaMask extension was used in last session and then uninstalled/disabled
      delete localStorage.username
      delete localStorage.meta_mask
    }
    console.warn('No web3 detected. Falling back to ' + url +
        '. You should remove this fallback when you deploy live, ' +
        "as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask")
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider(url))

  }

  init()
})

// If you want an ENTER in a text input field to do a click on a button then
// add the class "input-enter" to the input field and "btn-enter" to the button
// put both input field and button inside the same div with class="input-group"
$(document).on("keypress", ".input-enter", function(e){
    if (e.which == 13){
        $(this).closest(".input-group").find(".btn-enter").click();
    }
});

// ************** Generate the tree diagram	 *****************
// http://bl.ocks.org/d3noob/8375092
// for d3.v4 see https://bl.ocks.org/mbostock/4339184
let margin = {top: 0, right: 0, bottom: 0, left: 50},
  width = 960 - margin.right - margin.left,
  height = 300 - margin.top - margin.bottom

let tree = d3.layout.tree()
  .size([height, width]) // Compute the new tree layout.

let d3_i = 0,
  duration = 750,
  d3_root

let diagonal = d3.svg.diagonal()
  .projection(function (d) { return [d.y, d.x] })

let svg = d3.select('#influencers-graph').append('svg')
  .attr('width', width + margin.right + margin.left)
  .attr('height', height + margin.top + margin.bottom)
  .append('g')
  .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')

// Define the div for the tooltip
// http://bl.ocks.org/d3noob/a22c42db65eb00d4e369
let tooltip_div = d3.select('body').append('div')
  .attr('class', 'tooltip')
  .style('opacity', 0)

let d3_init_counter = 0
let d3_source

function d3_reset () {
  d3_root = null
  d3_source = null
  d3_init_counter = 0
  d3_i = 0
  svg.selectAll('*').remove()
  $('#influencers-graph-wrapper').hide()
  // $("#influencers-graph").empty();
}

function d3_init () {
  if (++d3_init_counter < 1) {
    return
  }

  // d3.select("#influencers-graph").style("height", "500px");
  d3.select(self.frameElement).style('height', height + 'px')

  let my_address = whoAmI()
  if (my_address) {
    let root = d3_add_event_children([my_address], null, 1)[0]
    if (root.children) {
      d3_root = root
      d3_update(d3_root)
      $('#influencers-graph-wrapper').show()
    }
  }
}

function d3_update (source) {
  if (!d3_root) return

  if (!source) {
    if (d3_source) {
      source = d3_source
    } else {
      source = d3_root
    }
  }
  d3_source = source

  let nodes = tree.nodes(d3_root).reverse(),
    links = tree.links(nodes)

    // Normalize for fixed-depth.
  nodes.forEach(function (d) {
    d.y = d.depth * 180
  })

  // Update the nodes…
  let node = svg.selectAll('g.node')
    .data(nodes, function (d) {
      return d.id || (d.id = ++d3_i)
    })

    // Enter any new nodes at the parent's previous position.
  let nodeEnter = node.enter().append('g')
    .attr('class', 'node')
    .attr('transform', function (d) {
      return 'translate(' + source.y0 + ',' + source.x0 + ')'
    })
    .on('click', d3_click)
    .on('mouseover', function (d) {
      tooltip_div.transition()
        .duration(200)
        .style('opacity', 0.9)
      tooltip_div.html('units ' + d.units + '<br/>' + 'rewards ' + d.rewards + '<br/>')
        .style('left', (d3.event.pageX) + 'px')
        .style('top', (d3.event.pageY - 28) + 'px')
    })
    .on('mouseout', function (d) {
      tooltip_div.transition()
        .duration(500)
        .style('opacity', 0)
    })

  nodeEnter.append('circle')
    .attr('r', 1e-6)
    .style('fill', function (d) {
      return d._children ? 'lightsteelblue' : '#fff'
    })

  nodeEnter.append('text')
    .attr('x', function (d) {
      return d.children || d._children ? -13 : 13
    })
    .attr('dy', '.35em')
    .attr('text-anchor', function (d) {
      return d.children || d._children ? 'end' : 'start'
    })
    .text(function (d) {
      return d.name || d.address
    })
    .attr('id', function (d) {
      return 'd3-' + d.d3_id
    })
    .style('fill-opacity', 1e-6)

    // Transition nodes to their new position.
  let nodeUpdate = node.transition()
    .duration(duration)
    .attr('transform', function (d) {
      return 'translate(' + d.y + ',' + d.x + ')'
    })

  let circles = nodeUpdate.select('circle')
    .attr('r', 10)
    .style('fill', function (d) {
      return (d._children ? 'lightsteelblue' : '#fff')
    })
  getTwoKeyContract(twoKeyContractAddress,
    TwoKeyContract_instance =>
      circles.style('stroke',
        d => (TwoKeyContract_instance.info.owner == d.address)
          ? '#f00' : (d.units) ? '#0f0' : 'steelblue'))

  nodeUpdate.select('text')
    .style('fill-opacity', 1)

    // Transition exiting nodes to the parent's new position.
  let nodeExit = node.exit().transition()
    .duration(duration)
    .attr('transform', function (d) {
      return 'translate(' + source.y + ',' + source.x + ')'
    })
    .remove()

  nodeExit.select('circle')
    .attr('r', 1e-6)

  nodeExit.select('text')
    .style('fill-opacity', 1e-6)

    // Update the links…
  let link = svg.selectAll('path.link')
    .data(links, function (d) {
      return d.target.id
    })

  link.style('stroke', (d) => {
    return (d.target.rewards || d.target.units) ? '#0f0' : '#ccc'
  })

  // Enter any new links at the parent's previous position.
  link.enter().insert('path', 'g')
    .attr('class', 'link')
    .attr('d', function (d) {
      let o = {x: source.x0, y: source.y0}
      return diagonal({source: o, target: o})
    })

  // Transition links to their new position.
  let linkUpdate = link.transition()
    .duration(duration)
    .attr('d', diagonal)

  linkUpdate.style('stroke', (d) => {
    return (d.target.rewards || d.target.units) ? '#0f0' : '#ccc'
  })

  // Transition exiting nodes to the parent's new position.
  link.exit().transition()
    .duration(duration)
    .attr('d', function (d) {
      let o = {x: source.x, y: source.y}
      return diagonal({source: o, target: o})
    })
    .remove()

    // Stash the old positions for transition.
  nodes.forEach(function (d) {
    d.x0 = d.x
    d.y0 = d.y
  })
}

// Toggle children on click.
function d3_click (d) {
  if (d.children) {
    d._children = d.children
    d.children = null
  } else {
    d.children = d._children
    d._children = null
  }
  d3_update(d)
}

function d3_add_event_children (addresses, parent, depth) {
  let childrens = []

  if (addresses) {
    for (let i = 0; i < addresses.length; i++) {
      let address = addresses[i]

      let node = {
        'address': address,
        'd3_id': ++unique_id,
        'parent': parent,
        'units': 0,
        'rewards': 0,
        'x0': height / 2,
        'y0': 0
      }
      childrens.push(node)

      function d3_wrapper (node) {
        // freeze node
        return function d3_cb (_name) {
          node.name = _name
        }
      }

      owner2name(address, '#d3-' + node.d3_id, d3_wrapper(node))

      getTwoKeyContract(twoKeyContractAddress, (TwoKeyContract_instance) => {
        let _units = TwoKeyContract_instance.units
        if (_units) _units = _units[address]

        if (_units) {
          view(TwoKeyContract_instance.constantInfo,
            constant_info => {
              let name, symbol, cost, bounty, quota, owner, ipfs_hash,
                unit_decimals;
              [name, symbol, cost, bounty, quota, owner, ipfs_hash, unit_decimals] = constant_info
              unit_decimals = unit_decimals.toNumber()

              _units = parseFloat('' + _units) / 10. ** unit_decimals
              let n = node
              n.units += _units
              n = n.parent
              while (n) {
                n.rewards += _units
                n = n.parent
              }
            })
        }

        let next_addresses = TwoKeyContract_instance.given_to
        if (next_addresses) next_addresses = next_addresses[address]

        let c = d3_add_event_children(next_addresses, node, depth - 1)
        if (depth > 0) {
          node.children = c
        } else {
          node._children = c
        }
      })
    }
  }

  if (childrens.length == 0) {
    return null
  } else {
    return childrens
  }
}
