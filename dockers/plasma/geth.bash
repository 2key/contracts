#!/bin/bash
echo "Starting GETH"

UNLOCK_ACCOUNT="0xc9fc28c92db63a6a3d9c4994793b97e5a18e7bd3,0xb3fa520368f2df7bed4df5185101f303f6c7decc,0x22d491bde2303f2f43325b2108d26f1eaba1e32b,0xe11ba2b4d45eaed5996cd0823791e0c93114882d,0x95ced938f7991cd0dfcb48f0a06a40fa1af46ebc,0x3e5e9111ae8eb78fe1cc3bb8915d5d461f3ef9a9,0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7"

if [ ! -d /geth/data/geth ]; then
	echo "/geth/data/geth not found, running 'geth init'..."
	geth --nodiscover --datadir=/geth/data --keystore=/geth/keys init /geth/genesis.json
	echo "...done!"
fi

echo ">>>>geth $@"

geth --datadir=/geth/data --keystore=/geth/keys --unlock "${UNLOCK_ACCOUNT}" --password "/geth/passwords.txt" "$@"
