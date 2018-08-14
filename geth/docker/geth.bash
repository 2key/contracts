#!/bin/bash
echo "Starting GETH"
if [ ! -d /root/.ethereum/keystore ]; then
	echo "/root/.ethereum/keystore not found, running 'geth init'..."
	geth init /root/genesis.json
	echo "...done!"

	for i in {1..3}
	do 
		echo "GENERATIONG KEY "$i" ON DEVNET"
		geth account import --password /root/passwords <(sed -n "$i"p /root/key.prv)
	done
fi

echo ">>>>geth $@"

geth "$@"