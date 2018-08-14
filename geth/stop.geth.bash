#!/bin/bash
docker rm $(docker stop $(docker ps -a -q --filter ancestor=2key/geth:dev --format="{{.ID}}"))
