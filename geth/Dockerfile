# Build Geth in a stock Go builder container
FROM ethereum/client-go:v1.8.11

RUN apk add --no-cache bash gawk sed grep bc coreutils

EXPOSE 8545 8546 30303 30303/udp
ENTRYPOINT ["/opt/geth/geth.bash"]
