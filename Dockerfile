ARG SOLC_VERSION=0.4.25
# TODO: Replace quay.io image with hyperledger/burrow image once it's updated with Vent event log feature
# ARG BURROW_VERSION=0.27.0
ARG BURROW_VERSION=0.27.0-dev-2019-08-02-fd379f4e
# This container provides the test environment from which the various test scripts
# can be run
# For solc binary
FROM ethereum/solc:$SOLC_VERSION as solc-builder
# TODO: Replace quay.io image with hyperledger/burrow image once it's updated with Vent event log feature
# Burrow version on which Blackstone is tested
# FROM hyperledger/burrow:$BURROW_VERSION as burrow-builder
FROM quay.io/monax/burrow:$BURROW_VERSION as burrow-builder

# Testing image
FROM alpine:3.9

RUN apk --update --no-cache add \
  bash \
  coreutils \
  curl \
  git \
  g++ \
  jq \
  libc6-compat \
  make \
  nodejs \
  nodejs-npm \
  openssh-client \
  parallel \
  python \
  py-crcmod \
  tar \
  shadow

ARG INSTALL_BASE=/usr/local/bin

COPY --from=burrow-builder /usr/local/bin/burrow $INSTALL_BASE/
COPY --from=solc-builder /usr/bin/solc $INSTALL_BASE/
# For doc pushing
COPY ssh_config /root/.ssh/config
# test chain config
COPY ./test/chain /app/test/chain
