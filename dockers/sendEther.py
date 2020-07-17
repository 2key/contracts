import requests
import json

def getAddress():
    headers = {
        'Content-Type': 'application/json',
    }

    data = '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}'

    response = requests.post('http://127.0.0.1:8545/', headers=headers, data=data)
    response = json.loads(response.text)
    return response["result"][0]


def sendEther():
    address = getAddress()
    headers = {
        'Content-Type': 'application/json',
    }

    data = '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"from": "%s","to":"0xb3fa520368f2df7bed4df5185101f303f6c7decc", "gas":"0x76c0","gasPrice":"0x9184e72a000","value":"0xC097CE7BC90715B34B9F1000000000"}],"id":1}' % (address)

    response = requests.post('http://127.0.0.1:8545/', headers=headers, data=data)

sendEther()
