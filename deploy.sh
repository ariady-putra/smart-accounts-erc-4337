#!/bin/bash
source .env
# forge script script/DeployFoundry.s.sol --broadcast --rpc-url http://127.0.0.1:8545 --account $ACCOUNT
forge script script/DeploySepolia.s.sol --broadcast --rpc-url $RPC_URL --account $ACCOUNT
