/* GENERATED BY TYPECHAIN VER. 0.2.7 */
/* tslint:disable */

import { BigNumber } from "bignumber.js";
import * as TC from "./typechain-runtime";

export class TwoKeyEconomy extends TC.TypeChainContract {
  public readonly rawWeb3Contract: any;

  public constructor(web3: any, address: string | BigNumber) {
    const abi = [
      {
        constant: true,
        inputs: [],
        name: "name",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_spender", type: "address" },
          { name: "_value", type: "uint256" }
        ],
        name: "approve",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: true,
        inputs: [
          { name: "_operator", type: "address" },
          { name: "_role", type: "string" }
        ],
        name: "checkRole",
        outputs: [],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "totalSupply",
        outputs: [{ name: "", type: "uint256" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [
          { name: "_operator", type: "address" },
          { name: "_role", type: "string" }
        ],
        name: "hasRole",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_from", type: "address" },
          { name: "_to", type: "address" },
          { name: "_value", type: "uint256" }
        ],
        name: "transferFrom",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "decimals",
        outputs: [{ name: "", type: "uint8" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "ROLE_CONTROLLER",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_spender", type: "address" },
          { name: "_subtractedValue", type: "uint256" }
        ],
        name: "decreaseApproval",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: true,
        inputs: [{ name: "_owner", type: "address" }],
        name: "balanceOf",
        outputs: [{ name: "", type: "uint256" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: false,
        inputs: [],
        name: "renounceOwnership",
        outputs: [],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "addr", type: "address" },
          { name: "roleName", type: "string" }
        ],
        name: "adminRemoveRole",
        outputs: [],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "owner",
        outputs: [{ name: "", type: "address" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "symbol",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_to", type: "address" },
          { name: "_value", type: "uint256" }
        ],
        name: "transfer",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "addr", type: "address" },
          { name: "roleName", type: "string" }
        ],
        name: "adminAddRole",
        outputs: [],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "getAdminRole",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "onlyControllerRole",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "ROLE_ADMIN",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_spender", type: "address" },
          { name: "_addedValue", type: "uint256" }
        ],
        name: "increaseApproval",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: true,
        inputs: [
          { name: "_owner", type: "address" },
          { name: "_spender", type: "address" }
        ],
        name: "allowance",
        outputs: [{ name: "", type: "uint256" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "getControllerRole",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: false,
        inputs: [{ name: "_newOwner", type: "address" }],
        name: "transferOwnership",
        outputs: [],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        inputs: [{ name: "_twoKeyAdmin", type: "address" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "constructor"
      },
      {
        anonymous: false,
        inputs: [{ indexed: true, name: "previousOwner", type: "address" }],
        name: "OwnershipRenounced",
        type: "event"
      },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "previousOwner", type: "address" },
          { indexed: true, name: "newOwner", type: "address" }
        ],
        name: "OwnershipTransferred",
        type: "event"
      },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "owner", type: "address" },
          { indexed: true, name: "spender", type: "address" },
          { indexed: false, name: "value", type: "uint256" }
        ],
        name: "Approval",
        type: "event"
      },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "from", type: "address" },
          { indexed: true, name: "to", type: "address" },
          { indexed: false, name: "value", type: "uint256" }
        ],
        name: "Transfer",
        type: "event"
      },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "operator", type: "address" },
          { indexed: false, name: "role", type: "string" }
        ],
        name: "RoleAdded",
        type: "event"
      },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "operator", type: "address" },
          { indexed: false, name: "role", type: "string" }
        ],
        name: "RoleRemoved",
        type: "event"
      },
      {
        constant: true,
        inputs: [],
        name: "getTokenName",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "getTokenSymbol",
        outputs: [{ name: "", type: "string" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [],
        name: "getTokenDecimals",
        outputs: [{ name: "", type: "uint8" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      }
    ];
    super(web3, address, abi);
  }

  static async createAndValidate(
    web3: any,
    address: string | BigNumber
  ): Promise<TwoKeyEconomy> {
    const contract = new TwoKeyEconomy(web3, address);
    const code = await TC.promisify(web3.eth.getCode, [address]);

    // in case of missing smartcontract, code can be equal to "0x0" or "0x" depending on exact web3 implementation
    // to cover all these cases we just check against the source code length — there won't be any meaningful EVM program in less then 3 chars
    if (code.length < 4) {
      throw new Error(`Contract at ${address} doesn't exist!`);
    }
    return contract;
  }

  public get name(): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.name, []);
  }

  public get totalSupply(): Promise<BigNumber> {
    return TC.promisify(this.rawWeb3Contract.totalSupply, []);
  }

  public get decimals(): Promise<BigNumber> {
    return TC.promisify(this.rawWeb3Contract.decimals, []);
  }

  public get ROLE_CONTROLLER(): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.ROLE_CONTROLLER, []);
  }

  public get owner(): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.owner, []);
  }

  public get symbol(): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.symbol, []);
  }

  public get getAdminRole(): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.getAdminRole, []);
  }

  public get onlyControllerRole(): Promise<boolean> {
    return TC.promisify(this.rawWeb3Contract.onlyControllerRole, []);
  }

  public get ROLE_ADMIN(): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.ROLE_ADMIN, []);
  }

  public get getControllerRole(): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.getControllerRole, []);
  }

  public get getTokenName(): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.getTokenName, []);
  }

  public get getTokenSymbol(): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.getTokenSymbol, []);
  }

  public get getTokenDecimals(): Promise<BigNumber> {
    return TC.promisify(this.rawWeb3Contract.getTokenDecimals, []);
  }

  public checkRole(
    _operator: BigNumber | string,
    _role: string
  ): Promise<void> {
    return TC.promisify(this.rawWeb3Contract.checkRole, [
      _operator.toString(),
      _role.toString()
    ]);
  }

  public hasRole(
    _operator: BigNumber | string,
    _role: string
  ): Promise<boolean> {
    return TC.promisify(this.rawWeb3Contract.hasRole, [
      _operator.toString(),
      _role.toString()
    ]);
  }

  public balanceOf(_owner: BigNumber | string): Promise<BigNumber> {
    return TC.promisify(this.rawWeb3Contract.balanceOf, [_owner.toString()]);
  }

  public allowance(
    _owner: BigNumber | string,
    _spender: BigNumber | string
  ): Promise<BigNumber> {
    return TC.promisify(this.rawWeb3Contract.allowance, [
      _owner.toString(),
      _spender.toString()
    ]);
  }

  public approveTx(
    _spender: BigNumber | string,
    _value: BigNumber | number
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(this, "approve", [
      _spender.toString(),
      _value.toString()
    ]);
  }
  public transferFromTx(
    _from: BigNumber | string,
    _to: BigNumber | string,
    _value: BigNumber | number
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "transferFrom",
      [_from.toString(), _to.toString(), _value.toString()]
    );
  }
  public decreaseApprovalTx(
    _spender: BigNumber | string,
    _subtractedValue: BigNumber | number
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "decreaseApproval",
      [_spender.toString(), _subtractedValue.toString()]
    );
  }
  public renounceOwnershipTx(): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "renounceOwnership",
      []
    );
  }
  public adminRemoveRoleTx(
    addr: BigNumber | string,
    roleName: string
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "adminRemoveRole",
      [addr.toString(), roleName.toString()]
    );
  }
  public transferTx(
    _to: BigNumber | string,
    _value: BigNumber | number
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(this, "transfer", [
      _to.toString(),
      _value.toString()
    ]);
  }
  public adminAddRoleTx(
    addr: BigNumber | string,
    roleName: string
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "adminAddRole",
      [addr.toString(), roleName.toString()]
    );
  }
  public increaseApprovalTx(
    _spender: BigNumber | string,
    _addedValue: BigNumber | number
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "increaseApproval",
      [_spender.toString(), _addedValue.toString()]
    );
  }
  public transferOwnershipTx(
    _newOwner: BigNumber | string
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "transferOwnership",
      [_newOwner.toString()]
    );
  }

  public OwnershipRenouncedEvent(eventFilter: {
    previousOwner?: BigNumber | string | Array<BigNumber | string>;
  }): TC.DeferredEventWrapper<
    { previousOwner: BigNumber | string },
    { previousOwner?: BigNumber | string | Array<BigNumber | string> }
  > {
    return new TC.DeferredEventWrapper<
      { previousOwner: BigNumber | string },
      { previousOwner?: BigNumber | string | Array<BigNumber | string> }
    >(this, "OwnershipRenounced", eventFilter);
  }
  public OwnershipTransferredEvent(eventFilter: {
    previousOwner?: BigNumber | string | Array<BigNumber | string>;
    newOwner?: BigNumber | string | Array<BigNumber | string>;
  }): TC.DeferredEventWrapper<
    { previousOwner: BigNumber | string; newOwner: BigNumber | string },
    {
      previousOwner?: BigNumber | string | Array<BigNumber | string>;
      newOwner?: BigNumber | string | Array<BigNumber | string>;
    }
  > {
    return new TC.DeferredEventWrapper<
      { previousOwner: BigNumber | string; newOwner: BigNumber | string },
      {
        previousOwner?: BigNumber | string | Array<BigNumber | string>;
        newOwner?: BigNumber | string | Array<BigNumber | string>;
      }
    >(this, "OwnershipTransferred", eventFilter);
  }
  public ApprovalEvent(eventFilter: {
    owner?: BigNumber | string | Array<BigNumber | string>;
    spender?: BigNumber | string | Array<BigNumber | string>;
  }): TC.DeferredEventWrapper<
    {
      owner: BigNumber | string;
      spender: BigNumber | string;
      value: BigNumber | number;
    },
    {
      owner?: BigNumber | string | Array<BigNumber | string>;
      spender?: BigNumber | string | Array<BigNumber | string>;
    }
  > {
    return new TC.DeferredEventWrapper<
      {
        owner: BigNumber | string;
        spender: BigNumber | string;
        value: BigNumber | number;
      },
      {
        owner?: BigNumber | string | Array<BigNumber | string>;
        spender?: BigNumber | string | Array<BigNumber | string>;
      }
    >(this, "Approval", eventFilter);
  }
  public TransferEvent(eventFilter: {
    from?: BigNumber | string | Array<BigNumber | string>;
    to?: BigNumber | string | Array<BigNumber | string>;
  }): TC.DeferredEventWrapper<
    {
      from: BigNumber | string;
      to: BigNumber | string;
      value: BigNumber | number;
    },
    {
      from?: BigNumber | string | Array<BigNumber | string>;
      to?: BigNumber | string | Array<BigNumber | string>;
    }
  > {
    return new TC.DeferredEventWrapper<
      {
        from: BigNumber | string;
        to: BigNumber | string;
        value: BigNumber | number;
      },
      {
        from?: BigNumber | string | Array<BigNumber | string>;
        to?: BigNumber | string | Array<BigNumber | string>;
      }
    >(this, "Transfer", eventFilter);
  }
  public RoleAddedEvent(eventFilter: {
    operator?: BigNumber | string | Array<BigNumber | string>;
  }): TC.DeferredEventWrapper<
    { operator: BigNumber | string; role: string },
    { operator?: BigNumber | string | Array<BigNumber | string> }
  > {
    return new TC.DeferredEventWrapper<
      { operator: BigNumber | string; role: string },
      { operator?: BigNumber | string | Array<BigNumber | string> }
    >(this, "RoleAdded", eventFilter);
  }
  public RoleRemovedEvent(eventFilter: {
    operator?: BigNumber | string | Array<BigNumber | string>;
  }): TC.DeferredEventWrapper<
    { operator: BigNumber | string; role: string },
    { operator?: BigNumber | string | Array<BigNumber | string> }
  > {
    return new TC.DeferredEventWrapper<
      { operator: BigNumber | string; role: string },
      { operator?: BigNumber | string | Array<BigNumber | string> }
    >(this, "RoleRemoved", eventFilter);
  }
}
