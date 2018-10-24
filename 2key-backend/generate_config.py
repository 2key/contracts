import json
import os

"""
==============
This script is going to fill config.json file with addresses and abi's from last build. 
This means whenever you do "truffle migrate", you need to run this script and update config file.
==============

==============
To run: $ python update_config.py
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
                abi[contract] = dictdump["abi"]
                dict[contract] = dictdump["networks"]["4"]["address"]
                final[contract] = {'abi ' : abi[contract], 'address' : dict[contract]}


for key in final:
    print key
with open('config.json', 'w') as config:
    json.dump(final, config)

# with open("config.json","r+") as jsonFile:
#     data = json.load(jsonFile)
#
#
#     data["TwoKeyAdmin"]["abi"] = abi["TwoKeyAdmin.json"]
#     data["TwoKeyAdmin"]["address"] = dict["TwoKeyAdmin.json"]
#
#     # data["cardContract"]["abi"] = abi["SeleneanCards.json"]
#     # data["cardContract"]["address"] = dict["SeleneanCards.json"]
#     #
#     # data["boosterContract"]["abi"] = abi["Booster.json"]
#     # data["boosterContract"]["address"] = dict["Booster.json"]
#
#     jsonFile.seek(0)
#     json.dump(data, jsonFile)
#     jsonFile.truncate()