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


def sendEther(to):
    address = getAddress()
    headers = {
        'Content-Type': 'application/json',
    }

    data = '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"from": "%s","to":"%s", "gas":"0x76c0","gasPrice":"0x9184e72a000","value":"0xC097CE7BC90715B34B9F1000000000"}],"id":1}' % (address,to)

    response = requests.post('http://127.0.0.1:8545/', headers=headers, data=data)
    print (response.text)


def sendEtherToAllTestAddresses():

    # Load deployer address as well.
    with open('../configurationFiles/accountsConfig.json') as f:
      data = json.load(f)


    addresses = [
        "0xb3fa520368f2df7bed4df5185101f303f6c7decc",
        "0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7",
        "0xf3c7641096bc9dc50d94c572bb455e56efc85412",
        "0xebadf86c387fe3a4378738dba140da6ce014e974",
        "0xec8b6aaee825e0bbc812ca13e1b4f4b038154688",
        "0xfc279a3c3fa62b8c840abaa082cd6b4073e699c8",
        "0xc744f2ddbca85a82be8f36c159be548022281c62",
        "0x1b00334784ee0360ddf70dfd3a2c53ccf51e5b96",
        "0x084d61962273589bf894c7b8794aa8915a06200f",
        "0xa7f9b1e9a4dbe008d4625898d73dbc2dc3346bf8",
        "0xa916227584A55CfE94733F03397cE37c0a0f7A74",
        data['address']
    ]

    for i in range(0,len(addresses)):
        sendEther(addresses[i])

sendEtherToAllTestAddresses()

