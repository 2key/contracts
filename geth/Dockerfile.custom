# Build Geth in a stock Go builder container
FROM golang:1.10-alpine as builder

RUN apk add --no-cache make gcc musl-dev linux-headers wget unzip
WORKDIR /root
RUN wget https://github.com/aydnep/go-ethereum/archive/master.zip
RUN unzip master.zip
RUN rm master.zip
RUN mv go-ethereum-master go-ethereum
WORKDIR /root/go-ethereum
RUN make geth

FROM alpine:latest

RUN apk add --no-cache bash gawk sed grep bc coreutils ca-certificates
COPY --from=builder /root/go-ethereum/build/bin/geth /usr/local/bin/

EXPOSE 8545 8546 30303 30303/udp
ENTRYPOINT ["/opt/geth/geth.bash"]
