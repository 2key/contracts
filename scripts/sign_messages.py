# This is a sample Python script.

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.
"""
 In order to test this script, in the same directory create ".env-sign" named file, and
 make sure it is following structure:
 ------
 RPC = <RPC>
 PK = <SIGNATORY_PK>
 ------

 Also, make sure to have installed "environs"
 (pip3 install environs)
"""

from web3 import Web3
from eth_account import messages, Account
from environs import Env

import os


def remove_0x(message):
    return message[2:]


def add_leading_0(message):
    while (len(message) < 64):
        message = '0' + message
    return message


def encode_array_of_addresses(addresses):
    result = ""
    for address in addresses:
        address = remove_0x(address) # Remove 0x from the beginning
        address = add_leading_0(address) # Add leading 0's to address
        result = result + address
    return '0x' + result


def encode_array_of_uints(uints):
    result = ""
    for uint in uints:
        result = result + add_leading_0(remove_0x(str(w3.toHex(uint))))

    return result


def build_messages(user_address, total_rewards_pending_wei, w3):
    message_1 = 'bytes binding user rewards'
    hexed_rewards = str(w3.toHex(total_rewards_pending_wei))
    message_2 = user_address + add_leading_0(remove_0x(hexed_rewards))
    return message_1, message_2


def build_messages_v2(referrer, campaign_addresses_array, pending_rewards_array, w3):
    message_1 = referrer
    message_2 = str(encode_array_of_addresses(campaign_addresses_array)) + encode_array_of_uints(pending_rewards_array)
    return message_1, message_2


def hash_messages(message1, message2, w3):
    hash1 = w3.solidityKeccak(['bytes'], [message1])
    hash2 = w3.solidityKeccak(['bytes'], [message2])

    final_hash = w3.solidityKeccak(
        ['bytes32', 'bytes32'],
        [w3.toHex(hash1), w3.toHex(hash2)]
    )

    return remove_0x(str(w3.toHex(final_hash)))


def sign_messages(message1, message2, private_key_signatory, w3):
    final_hash = hash_messages(message1, message2, w3)
    message_to_sign = messages.encode_defunct(hexstr=final_hash)
    signed_message = Account.sign_message(message_to_sign, private_key=private_key_signatory)
    finalize_signature(signed_message.signature.hex())


def finalize_signature(signature):
    n = len(signature)
    ### Take last 2 parts of sig
    v = hex(int(signature[n-2:],16) + 32)
    signature = signature[:n-2] + remove_0x(str(v))
    print("signature =", signature)


def build_signature(user_address, total_rewards_pending_wei, private_key_signatory, w3):
    message1, message2 = build_messages(user_address, total_rewards_pending_wei, w3)
    sign_messages(message1, message2, private_key_signatory, w3)


def build_signature_v2(referrer, campaign_addresses_array, pending_rewards_array, private_key_signatory, w3):
    message1, message2 = build_messages_v2(referrer, campaign_addresses_array, pending_rewards_array, w3)
    sign_messages(message1, message2, private_key_signatory, w3)


if __name__ == '__main__':
    env = Env()
    env.read_env('.env-sign')
    RPC = env('RPC')
    SIGNATORY_PK = env('PK')
    w3 = Web3(Web3.HTTPProvider(RPC))
    referrer = "0x6567D655953f38d29f57B1ebd55CA6Cae4dAa12B"
    campaign_addresses_array = ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
    pending_rewards_array = [48000000000000000000,39000000000000000000]
    build_signature_v2(referrer, campaign_addresses_array, pending_rewards_array, SIGNATORY_PK, w3)
#     build_signature('0x98a206fedc0e0ab0a45cb82a315c94087a79aed7', 24136582388247820000,
#                     SIGNATORY_PK, w3)
