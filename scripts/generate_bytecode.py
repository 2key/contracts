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

def generate_bytecode_for_transfering_tokens(deployer_address, token_amount):
    token_amount = int(token_amount) * (10**18)
    method_name_and_params = "transfer2KeyTokens(address,uint256)"
    types = ["address","uint256"]
    values = [deployer_address,token_amount]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_upgrading_contracts(contract_name, contract_version):
    method_name_and_params = "upgradeContract(string,string)"
    types = ["string","string"]
    values = [contract_name, contract_version]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_changing_rewards_release_date(newDate):
    newDate = int(newDate)
    method_name_and_params = "setNewTwoKeyRewardsReleaseDate(uint256)"
    types = ["uint256"]
    values = [newDate]
    print('Transaction bytecode: ' +generate_bytecode(method_name_and_params, types, values))

###
# 1. Add Member
# 2. Remove member
# 3. Send eth
# 4. Set new public trading date
# TODO: Add in the main examples how to generate the bytecode for each one
###

if __name__ == "__main__":
    arg1 = sys.argv[1]
#    arg2 = sys.argv[2]
#    arg3 = sys.argv[3]

#    if(arg3 == "upgrade_contracts"):
#        generate_bytecode_for_upgrading_contracts(arg1,arg2)
#    if(arg3 == "transfer_tokens") :
#        generate_bytecode_for_transfering_tokens(arg1,arg2)

    generate_bytecode_for_changing_rewards_release_date(arg1)

