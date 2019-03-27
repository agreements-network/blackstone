ARG SOLC_VERSION=0.4.25
ARG BURROW_IMAGE="quay.io/monax/burrow:0.24.6-dev-2019-03-22-fd132ac3"
# This container provides the test environment from which the various test scripts
# can be run
# For solc binary
FROM ethereum/solc:$SOLC_VERSION as solc-builder
# Burrow version on which Blackstone is tested
FROM $BURROW_IMAGE as burrow-builder
#FROM quay.io/monax/burrow:0.24.1-dev-2019-02-28-0b9bc4e9 as burrow-builder
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

# Create user and group unless they already exist
ARG UID=0
ARG GID=0
ARG HOME_DIR=/home/api
COPY ./scripts/ensure_user.sh $INSTALL_BASE/
RUN ensure_user.sh $UID $GID $HOME_DIR

# For doc pushing
COPY ssh_config $HOME_DIR/.ssh/config
# test chain config
COPY ./test/chain /app/test/chain
RUN chown -R $UID:$GID $HOME_DIR/.ssh/config /app/test/chain
USER $UID:$GID
