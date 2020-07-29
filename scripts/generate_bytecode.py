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

def generate_bytecode_for_taking_fees_from_manager():
    method_name_and_params = "withdrawEtherCollectedFromFeeManager()"
    types = []
    values = []
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_chaging_moderator_fee_on_public(moderator_fee):
    moderator_fee = int(moderator_fee)
    method_name_and_params = "setDefaultIntegratorFeePercent(uint256)"
    types = ["uint256"]
    values = [moderator_fee]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_changing_moderator_fee_on_plasma(moderator_fee):
    moderator_fee = int(moderator_fee)
    method_name_and_params = "setModeratorFee(uint256)"
    types = ["uint256"]
    values = [moderator_fee]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_enabling_kyber_trade(reserve_contract_address):
    method_name_and_params = "enableTradeInKyber(address)"
    types = ["address"]
    values = [reserve_contract_address]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_disabling_kyber_trade(reserve_contract_address):
    method_name_and_params = "disableTradeInKyber(address)"
    types = ["address"]
    values = [reserve_contract_address]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_withdrawing_ether_from_reserve(reserve_contract_address, amount_of_ether):
    amount_of_ether = int(amount_of_ether)
    method_name_and_params = "withdrawEtherFromKyberReserve(address,uint256)"
    types = ["address","uint256"]
    values = [reserve_contract_address, amount_of_ether]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_withdrawal_of_tokens_from_reserve(reserve_contract_address, token_address, amount, beneficiary):
    amount = int(amount)
    method_name_and_params = "withdrawTokensFromKyberReserve(address,address,uint256,address)"
    types = ["address","address","uint256","address"]
    values = [reserve_contract_address, token_address, amount, beneficiary]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_setting_kyber_reserve_contract_address(reserve_contract_address):
    method_name_and_params = "setKyberReserveContractAddressOnUpgradableExchange(address)"
    types = ["address"]
    values = [reserve_contract_address]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_setting_contracts_in_kyber(reserve_contract_address, kyber_network, conversion_rates, sanity_rates):
    method_name_and_params = "setContractsKyber(address,address,address,address)"
    types = ["address","address","address","address"]
    values = [reserve_contract_address, kyber_network, conversion_rates, sanity_rates]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_setting_new_spread(new_spread_wei):
    new_spread_wei = int(new_spread_wei)
    method_name_and_params = "setNewSpreadWei(uint256)"
    types = ["uint256"]
    values = [new_spread_wei]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_migrating_fee_manager_state():
    method_name_and_params = "migrateCurrentFeeManagerStateToAdminAndWithdrawFunds()"
    types = []
    values = []
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_kyber_fees_withdraw_from_reserve(reserve_contract_address, pricing_contract_address):
    method_name_and_params = "withdrawFeesFromKyber(address,address)"
    types = ["address","address"]
    values = [reserve_contract_address, pricing_contract_address]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_withdrawal_of_dai_from_upgradable_exchange_to_admin(amount_of_token):
    amount_of_token = int(amount_of_token)
    method_name_and_params = "withdrawDAIAvailableToFillReserveFromUpgradableExchange(uint256)"
    types = ["uint256"]
    values = [amount_of_token]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_to_withdraw_upgradable_exchange_dai_collected_from_admin_contract(beneficiary, amount):
    amount = int(amount)
    method_name_and_params = "withdrawUpgradableExchangeDaiCollectedFromAdmin(address,uint256)"
    types = ["address","uint256"]
    values = [beneficiary,amount]
    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

def generate_bytecode_for_setting_liquidity_params(
        _kyberLiquidityPricing,
        _rInFp,
        _pMinInFp,
        _numFpBits,
        _maxCapBuyInWei,
        _maxCapSellInWei,
        _feeInBps,
        _maxTokenToEthRateInPrecision,
        _minTokenToEthRateInPrecision
    ):

    _rInFp = int(_rInFp)
    _pMinInFp = int(_pMinInFp)
    _numFpBits = int(_numFpBits)
    _maxCapBuyInWei = int(_maxCapBuyInWei)
    _maxCapSellInWei = int(_maxCapSellInWei)
    _feeInBps = int(_feeInBps)
    _maxTokenToEthRateInPrecision = int(_maxTokenToEthRateInPrecision)
    _minTokenToEthRateInPrecision = int(_minTokenToEthRateInPrecision)


    method_name_and_params = "setLiquidityParametersInKyber(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"
    types = ["address","uint256","uint256","uint256","uint256","uint256","uint256","uint256","uint256"]
    values = [
        _kyberLiquidityPricing,
        _rInFp,
        _pMinInFp,
        _numFpBits,
        _maxCapBuyInWei,
        _maxCapSellInWei,
        _feeInBps,
        _maxTokenToEthRateInPrecision,
        _minTokenToEthRateInPrecision
    ]

    print('Transaction bytecode: ' + generate_bytecode(method_name_and_params, types, values))

if __name__ == "__main__":
    arg1 = sys.argv[1] #Method name
    print('Action being performed: ',arg1)
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
    if(arg1 == "withdrawRewardsFromFeeManager"):
        generate_bytecode_for_taking_fees_from_manager()
    if(arg1 == "setModeratorFeePlasma"):
        generate_bytecode_for_changing_moderator_fee_on_plasma(sys.argv[2])
    if(arg1 == "setModeratorFeePublic"):
        generate_bytecode_for_chaging_moderator_fee_on_public(sys.argv[2])
    if(arg1 == "setLiquidityParamsKyber"):
        generate_bytecode_for_setting_liquidity_params(
            sys.argv[2],
            sys.argv[3],
            sys.argv[4],
            sys.argv[5],
            sys.argv[6],
            sys.argv[7],
            sys.argv[8],
            sys.argv[9],
            sys.argv[10]
        )
    if(arg1 == "enableKyberTrade"):
        generate_bytecode_for_enabling_kyber_trade(sys.argv[2])
    if(arg1 == "disableKyberTrade"):
        generate_bytecode_for_disabling_kyber_trade(sys.argv[2])
    if(arg1 == "withdrawEtherFromReserve"):
        generate_bytecode_for_withdrawing_ether_from_reserve(sys.argv[2],sys.argv[3])
    if(arg1 == "withdrawTokensFromReserve"):
        generate_bytecode_for_withdrawal_of_tokens_from_reserve(
            sys.argv[2],
            sys.argv[3],
            int(sys.argv[4]),
            sys.argv[5]
        )
    if(arg1 == "setKyberReserveContract"):
        generate_bytecode_for_setting_kyber_reserve_contract_address(sys.argv[2])
    if(arg1 == "setContracts"):
        generate_bytecode_for_setting_contracts_in_kyber(
            sys.argv[2],
            sys.argv[3],
            sys.argv[4],
            sys.argv[5]
        )
    if(arg1 == "pullKyberFeesFromReserve"):
        generate_bytecode_for_kyber_fees_withdraw_from_reserve(sys.argv[2],sys.argv[3])
    if(arg1 == "setSpread"):
        generate_bytecode_for_setting_new_spread(sys.argv[2])
    if(arg1 == "migrateFeeManagerState"):
        generate_bytecode_for_migrating_fee_manager_state()
    if(arg1 == "withdrawDAIFromUpgradableExchangeToAdmin"):
        generate_bytecode_for_withdrawal_of_dai_from_upgradable_exchange_to_admin(sys.argv[2])
    if(arg1 == "withdrawUpgradableExchangeDAICollectedFromAdminContract"):
        generate_bytecode_to_withdraw_upgradable_exchange_dai_collected_from_admin_contract(sys.argv[2],sys.argv[3])
    print_line()
