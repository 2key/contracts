# Build Geth in a stock Go builder container
FROM ethereum/client-go

RUN apk add --no-cache bash gawk sed grep bc coreutils

COPY ./docker/genesis.dev.json /root/genesis.json
COPY ./docker/key.prv /root/key.prv
COPY ./docker/passwords.dev /root/passwords
COPY ./docker/geth.bash /root/geth.bash

RUN ["chmod", "+x", "/root/geth.bash"]

EXPOSE 8545 8546 30303 30303/udp
ENTRYPOINT ["/root/geth.bash"]
