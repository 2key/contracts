from web3 import Web3
from eth_abi import encode_abi
import sys

def generate_selector(method_name_and_params):
    method_selector = Web3.sha3(text = method_name_and_params)[0:4].hex()
    return method_selector



def generate_bytecode(method_name_and_params,types,values):
    method_selector = generate_selector(method_name_and_params)
    packed_args = encode_abi(types,values).hex()
    bytecode = '0x' + method_selector + packed_args
    return (bytecode)


if __name__ == "__main__":
    deployer_address = sys.argv[1]
    token_amount = int(sys.argv[2]) * (10**18)
    method_name_and_params = "transfer2KeyTokens(address,uint256)"
    types = ["address","uint256"]
    values = [deployer_address,token_amount]

    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))