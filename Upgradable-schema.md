# Upgradeability using Inherited Storage (proposed by open-zeppelin initially)

In this readme, let's name the contract we'd like to support upgradability: ContractV1, ContractV2, etc.
The idea of this approach is to allow us to upgrade a contract's behavior, assuming that each version will follow the 
storage structure of the previous one. 

The approach consists in having a proxy that delegates calls to specific implementations which can be upgraded, without
changing the storage structure of the previous implementations, but having the chance to add new state variables. Given
the proxy uses `delegatecall` to resolve the requested behaviors, the upgradeable contract's state (ContractV1, ContractV2) will be stored in 
the proxy contract itself. 

We have two really different kinds of data, one related to the upgradeability mechanism and another 
strictly related to the ContractV1

Schema: 
            
                   -------             =========================
                  | Proxy |           ║  UpgradeabilityStorage  ║
                   -------             =========================
                      ↑                 ↑                     ↑            
                     ---------------------              -------------
                    | UpgradeabilityProxy |            | Upgradeable |
                     ---------------------              ------------- 
                                                          ↑        ↑
                                             ------------------      ------------------
                                            |    ContractV1    |  ← |    ContractV2    |         
                                             ------------------      ------------------
                                          

`Proxy`, `UpgradeabilityProxy` and `UpgradeabilityStorage` are generic contracts that can be used to implement
upgradeability through proxies.  

`UpgradeabilityProxy` is the contract that will delegate calls to specific implementations of the logic contract behavior. 
These behaviors are the code that can be upgraded by the token developer (e.g. `ContractV1` and `ContractV2`). 

The `UpgradeabilityStorage` contract holds data needed for upgradeability, which will be inherited from each contract 
(ContractV1,ContractV2) behavior though `Upgradeable`. Then, each contract behavior defines all the necessary state 
variables to carry out their storage. Notice that `ContractV1` inherits the same storage structure defined in `ContractV2`. 
This is a requirement of the proposed approach to ensure the proxy storage is not messed up.


### How to Initialize

```
Deploy a Registry contract
Deploy an initial version of your contract (v1). Make sure it inherits the Upgradeable contract
Register the address of your initial version to the Registry
Ask the Registry contract to create an UpgradeabilityProxy instance
Call your UpgradeabilityProxy to upgrade to the your initial version of the contract

```
### How to Upgrade
```
Deploy a new version of your contract (v2) that inherits from your initial version to make sure it keeps the storage structure of the proxy and the one in the initial version of your contract.
Register the new version of your contract to the Registry
Call your UpgradeabilityProxy instance to upgrade to the new registered version.
```
### Key Takeaways

We can introduce upgraded functions as well as new functions and new state variables in future deployed logic contracts by still calling the same UpgradeabilityProxy contract.

