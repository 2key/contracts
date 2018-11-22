import json
import os

"""
==============
To run: $ python generate_config.py
==============

"""
directory = "../build/contracts"
dict = {}
abi = {}
final = {}
for contract in os.listdir(directory):
    if contract.endswith(".json"):
        with open(os.path.join(directory,contract)) as json_contract:
            dictdump = json.loads(json_contract.read())
            if(dictdump["abi"] != None and dictdump["networks"].get("4") != None):
                contract = contract[0:(len(contract)-5)]
                abi[contract] = dictdump["abi"]
                dict[contract] = dictdump["networks"]["4"]["address"]
                final[contract] = {'abi' : abi[contract], 'address' : dict[contract]}



with open('config.json', 'w') as config:
    json.dump(final, config)
