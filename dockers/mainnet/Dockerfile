# Build Geth in a stock Go builder container
FROM ethereum/client-go:v1.8.23

RUN apk add --no-cache bash gawk sed grep bc coreutils

COPY genesis.json /geth/genesis.json
COPY passwords.txt /geth/passwords.txt
COPY keys /geth/keys

WORKDIR /
COPY ./geth.bash /geth.bash
RUN chmod +x /geth.bash

EXPOSE 8545 8546 30303 30303/udp
ENTRYPOINT ["/geth.bash"]
