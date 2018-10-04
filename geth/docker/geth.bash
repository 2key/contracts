#!/bin/bash
echo "Starting GETH"
if [ ! -d /geth/data/keystore ]; then
	echo "/geth/data/keystore not found, running 'geth init'..."
	geth init --datadir=/geth/data /opt/geth/genesis.2key.json
	echo "...done!"

	for i in {1..13}
	do
		echo "GENERATIONG KEY "$i" ON DEVNET"
		geth --datadir=/geth/data account import --password /opt/geth/passwords <(sed -n "$i"p /opt/geth/key.prv)
	done
fi

echo ">>>>geth $@"

geth "$@"
