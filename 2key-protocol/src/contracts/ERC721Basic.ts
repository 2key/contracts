/* GENERATED BY TYPECHAIN VER. 0.2.7 */
/* tslint:disable */

import { BigNumber } from "bignumber.js";
import * as TC from "./typechain-runtime";

export class ERC721Basic extends TC.TypeChainContract {
  public readonly rawWeb3Contract: any;

  public constructor(web3: any, address: string | BigNumber) {
    const abi = [
      {
        constant: true,
        inputs: [{ name: "_interfaceId", type: "bytes4" }],
        name: "supportsInterface",
        outputs: [{ name: "", type: "bool" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "_from", type: "address" },
          { indexed: true, name: "_to", type: "address" },
          { indexed: true, name: "_tokenId", type: "uint256" }
        ],
        name: "Transfer",
        type: "event"
      },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "_owner", type: "address" },
          { indexed: true, name: "_approved", type: "address" },
          { indexed: true, name: "_tokenId", type: "uint256" }
        ],
        name: "Approval",
        type: "event"
      },
      {
        anonymous: false,
        inputs: [
          { indexed: true, name: "_owner", type: "address" },
          { indexed: true, name: "_operator", type: "address" },
          { indexed: false, name: "_approved", type: "bool" }
        ],
        name: "ApprovalForAll",
        type: "event"
      },
      {
        constant: true,
        inputs: [{ name: "_owner", type: "address" }],
        name: "balanceOf",
        outputs: [{ name: "_balance", type: "uint256" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [{ name: "_tokenId", type: "uint256" }],
        name: "ownerOf",
        outputs: [{ name: "_owner", type: "address" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: true,
        inputs: [{ name: "_tokenId", type: "uint256" }],
        name: "exists",
        outputs: [{ name: "_exists", type: "bool" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_to", type: "address" },
          { name: "_tokenId", type: "uint256" }
        ],
        name: "approve",
        outputs: [],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: true,
        inputs: [{ name: "_tokenId", type: "uint256" }],
        name: "getApproved",
        outputs: [{ name: "_operator", type: "address" }],
        payable: false,
        stateMutability: "view",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_operator", type: "address" },
          { name: "_approved", type: "bool" }
        ],
        name: "setApprovalForAll",
        outputs: [],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: true,
        inputs: [
          { name: "_owner", type: "address" },
          { name: "_operator", type: "address" }
        ],
        name: "isApprovedForAll",
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
          { name: "_tokenId", type: "uint256" }
        ],
        name: "transferFrom",
        outputs: [],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_from", type: "address" },
          { name: "_to", type: "address" },
          { name: "_tokenId", type: "uint256" }
        ],
        name: "safeTransferFrom",
        outputs: [],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_from", type: "address" },
          { name: "_to", type: "address" },
          { name: "_tokenId", type: "uint256" },
          { name: "_data", type: "bytes" }
        ],
        name: "safeTransferFrom",
        outputs: [],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      }
    ];
    super(web3, address, abi);
  }

  static async createAndValidate(
    web3: any,
    address: string | BigNumber
  ): Promise<ERC721Basic> {
    const contract = new ERC721Basic(web3, address);
    const code = await TC.promisify(web3.eth.getCode, [address]);

    // in case of missing smartcontract, code can be equal to "0x0" or "0x" depending on exact web3 implementation
    // to cover all these cases we just check against the source code length — there won't be any meaningful EVM program in less then 3 chars
    if (code.length < 4) {
      throw new Error(`Contract at ${address} doesn't exist!`);
    }
    return contract;
  }

  public supportsInterface(_interfaceId: string): Promise<boolean> {
    return TC.promisify(this.rawWeb3Contract.supportsInterface, [
      _interfaceId.toString()
    ]);
  }

  public balanceOf(_owner: BigNumber | string): Promise<BigNumber> {
    return TC.promisify(this.rawWeb3Contract.balanceOf, [_owner.toString()]);
  }

  public ownerOf(_tokenId: BigNumber | number): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.ownerOf, [_tokenId.toString()]);
  }

  public exists(_tokenId: BigNumber | number): Promise<boolean> {
    return TC.promisify(this.rawWeb3Contract.exists, [_tokenId.toString()]);
  }

  public getApproved(_tokenId: BigNumber | number): Promise<string> {
    return TC.promisify(this.rawWeb3Contract.getApproved, [
      _tokenId.toString()
    ]);
  }

  public isApprovedForAll(
    _owner: BigNumber | string,
    _operator: BigNumber | string
  ): Promise<boolean> {
    return TC.promisify(this.rawWeb3Contract.isApprovedForAll, [
      _owner.toString(),
      _operator.toString()
    ]);
  }

  public approveTx(
    _to: BigNumber | string,
    _tokenId: BigNumber | number
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(this, "approve", [
      _to.toString(),
      _tokenId.toString()
    ]);
  }
  public setApprovalForAllTx(
    _operator: BigNumber | string,
    _approved: boolean
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "setApprovalForAll",
      [_operator.toString(), _approved.toString()]
    );
  }
  public transferFromTx(
    _from: BigNumber | string,
    _to: BigNumber | string,
    _tokenId: BigNumber | number
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "transferFrom",
      [_from.toString(), _to.toString(), _tokenId.toString()]
    );
  }
  public safeTransferFromTx(
    _from: BigNumber | string,
    _to: BigNumber | string,
    _tokenId: BigNumber | number
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "safeTransferFrom",
      [_from.toString(), _to.toString(), _tokenId.toString()]
    );
  }

  public TransferEvent(eventFilter: {
    _from?: BigNumber | string | Array<BigNumber | string>;
    _to?: BigNumber | string | Array<BigNumber | string>;
    _tokenId?: BigNumber | number | Array<BigNumber | number>;
  }): TC.DeferredEventWrapper<
    {
      _from: BigNumber | string;
      _to: BigNumber | string;
      _tokenId: BigNumber | number;
    },
    {
      _from?: BigNumber | string | Array<BigNumber | string>;
      _to?: BigNumber | string | Array<BigNumber | string>;
      _tokenId?: BigNumber | number | Array<BigNumber | number>;
    }
  > {
    return new TC.DeferredEventWrapper<
      {
        _from: BigNumber | string;
        _to: BigNumber | string;
        _tokenId: BigNumber | number;
      },
      {
        _from?: BigNumber | string | Array<BigNumber | string>;
        _to?: BigNumber | string | Array<BigNumber | string>;
        _tokenId?: BigNumber | number | Array<BigNumber | number>;
      }
    >(this, "Transfer", eventFilter);
  }
  public ApprovalEvent(eventFilter: {
    _owner?: BigNumber | string | Array<BigNumber | string>;
    _approved?: BigNumber | string | Array<BigNumber | string>;
    _tokenId?: BigNumber | number | Array<BigNumber | number>;
  }): TC.DeferredEventWrapper<
    {
      _owner: BigNumber | string;
      _approved: BigNumber | string;
      _tokenId: BigNumber | number;
    },
    {
      _owner?: BigNumber | string | Array<BigNumber | string>;
      _approved?: BigNumber | string | Array<BigNumber | string>;
      _tokenId?: BigNumber | number | Array<BigNumber | number>;
    }
  > {
    return new TC.DeferredEventWrapper<
      {
        _owner: BigNumber | string;
        _approved: BigNumber | string;
        _tokenId: BigNumber | number;
      },
      {
        _owner?: BigNumber | string | Array<BigNumber | string>;
        _approved?: BigNumber | string | Array<BigNumber | string>;
        _tokenId?: BigNumber | number | Array<BigNumber | number>;
      }
    >(this, "Approval", eventFilter);
  }
  public ApprovalForAllEvent(eventFilter: {
    _owner?: BigNumber | string | Array<BigNumber | string>;
    _operator?: BigNumber | string | Array<BigNumber | string>;
  }): TC.DeferredEventWrapper<
    {
      _owner: BigNumber | string;
      _operator: BigNumber | string;
      _approved: boolean;
    },
    {
      _owner?: BigNumber | string | Array<BigNumber | string>;
      _operator?: BigNumber | string | Array<BigNumber | string>;
    }
  > {
    return new TC.DeferredEventWrapper<
      {
        _owner: BigNumber | string;
        _operator: BigNumber | string;
        _approved: boolean;
      },
      {
        _owner?: BigNumber | string | Array<BigNumber | string>;
        _operator?: BigNumber | string | Array<BigNumber | string>;
      }
    >(this, "ApprovalForAll", eventFilter);
  }
}
