from web3 import Web3
from eth_abi import encode_abi
import sys

def print_line():
    print('--------------------------------------------------------------------------------------------------------')


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

def generate_bytecode_for_changing_rewards_release_date(new_date):
    newDate = int(new_date)
    method_name_and_params = "setNewTwoKeyRewardsReleaseDate(uint256)"
    types = ["uint256"]
    values = [new_date]
    print('Transaction bytecode: ' +generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_adding_new_member(target_member, member_name, voting_power):
    voting_power = int(voting_power)
    method_name_and_params = "addMember(address,bytes32,uint256)"
    types=["address","bytes32","uint256"]
    values = [target_member, member_name, voting_power]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_removing_member(target_member):
    method_name_and_params = "removeMember(address)"
    types=["address"]
    values = [target_member]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_freezing_transfers():
    method_name_and_params = "freezeTransfersInEconomy()"
    types = []
    values = []
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_unfreezing_transfers():
    method_name_and_params = "unfreezeTransfersInEconomy()"
    types = []
    values = []
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_replacing_contract(contract_name, new_contract_address):
    method_name_and_params = "changeNonUpgradableContract(string,address)"
    types = ["string","address"]
    values = [contract_name, new_contract_address]
    print ('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_approving_new_campaign_version(campaign_type, version_to_approve):
    method_name_and_params = "approveCampaignVersion(string,string)"
    types = ["string","string"]
    values = [campaign_type, version_to_approve]
    print ('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_adding_core_devs(core_dev):
    core_devs_array = [core_dev]
    method_name_and_params = "addCoreDevsToMaintainerRegistry(address[])"
    types = ["address[]"]
    values = [core_devs_array]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_adding_core_devs_plasma(core_dev):
    core_devs_array = [core_dev]
    method_name_and_params = "addCoreDevs(address[])"
    types = ["address[]"]
    values = [core_devs_array]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))


if __name__ == "__main__":
    arg1 = sys.argv[1] #Method name

    print('\n')

    if(arg1 == "transfer2KeyTokens"):
        generate_bytecode_for_transfering_tokens(sys.argv[2], sys.argv[3])
    if(arg1 == "upgradeContract"):
        generate_bytecode_for_upgrading_contracts(sys.argv[2], sys.argv[3])
    if(arg1 == "approveNewCampaign"):
        generate_bytecode_for_approving_new_campaign_version(sys.argv[2], sys.argv[3])
    if(arg1 == "setNewTwoKeyRewardsReleaseDate"):
        generate_bytecode_for_changing_rewards_release_date(int(sys.argv[2]))
    if(arg1 == "addMember"):
        generate_bytecode_for_adding_new_member(sys.argv[2],sys.argv[3],sys.argv[4])
    if(arg1 == "removeMember"):
        generate_bytecode_for_removing_member(sys.argv[2])
    if(arg1 == "freezeTransfers"):
        generate_bytecode_for_freezing_transfers()
    if(arg1 == "unfreezeTransfers"):
        generate_bytecode_for_unfreezing_transfers()
    if(arg1 == "changeNonUpgradableContract"):
        generate_bytecode_for_replacing_contract(sys.argv[2], sys.argv[3])
    if(arg1 == "addCoreDevs"):
        generate_bytecode_for_adding_core_devs(sys.argv[2])
    if(arg1 == "addCoreDevsPlasma"):
        generate_bytecode_for_adding_core_devs_plasma(sys.argv[2])

    print_line()
