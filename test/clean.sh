#!/usr/bin/env bash
set +e

# files and dirs accumulated during chain deployment/testing
rm -f ./test/chain/burrow.log
rm -rf ./test/chain/.burrow

#files and dirs accumulated during contracts deployment/testing
rm -f ./contracts/src/*.output.json
rm -f ./test*.log
rm -rf ./contracts/src/bin/*

# files and dirs accumulated by API deployment/testing
rm -rf ./api/public-abi
rm -rf ./api/logs

# files and dirs accumulated by document generation
rm -rf ./docs/docdev
rm -rf ./docs/apidoc

if [[ "$1" == "all" ]]; then
  rm -rf ./api/node_modules
  rm -rf ./docs/generator/node_modules
  rm -rf ./contracts/src/bin
fi
