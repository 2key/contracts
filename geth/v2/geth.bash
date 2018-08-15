#!/bin/bash
echo "Starting GETH"
if [ ! -d /geth/data/keystore ]; then
	echo "/geth/data/keystore not found, running 'geth init'..."
	geth init --datadir=/geth/data /geth/genesis.json
	echo "...done!"

	for i in {1..3}
	do 
		echo "GENERATIONG KEY "$i" ON DEVNET"
		geth --datadir=/geth/data account import --password /geth/passwords <(sed -n "$i"p /geth/key.prv)
	done
fi

echo ">>>>geth $@"

geth "$@"
