ARG SOLC_VERSION=0.4.25
ARG BURROW_REPO=hyperledger/burrow
ARG BURROW_VERSION=0.26.2
# This container provides the test environment from which the various test scripts
# can be run
# For solc binary
FROM ethereum/solc:$SOLC_VERSION as solc-builder
# Burrow version on which Blackstone is tested
FROM $BURROW_REPO:$BURROW_VERSION as burrow-builder

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
