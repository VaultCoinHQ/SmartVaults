#!/bin/bash

#
# rm ~/bitcoin && ln -s ~/projects/bitcoin-25.0/bin ~/bitcoin
#

echo "-------------"
echo "Stopping Bitcoind if it is already running"
echo "-------------"

#stop bitcoind if it running
bitcoin-cli stop >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Updating Bitcoind configuration"
echo "-------------"

mkdir -p ~/.bitcoin

cat <<- EOM > ~/.bitcoin/bitcoin.conf
## Generated - `date`
## bitcoin.conf configuration file. Lines beginning with # are comments.
##
daemon=1
regtest=1

listen=0

#addresstype=legacy
#changetype=legacy

[regtest]
# JSON-RPC options (for controlling a running Bitcoin/bitcoind process)
rpcuser=coinvault
rpcpassword=my_hen_lays_two_eggs_a_day
rpcport=8332

# server=1 tells Bitcoin-Qt and bitcoind to accept JSON-RPC commands
server=1
#prune=5500
txindex=1
EOM

echo "Done"

# set -x #echo on

echo "-------------"
echo "Refreshing & Restarting Bitcoind"
echo "-------------"

#start afresh
rm -R ~/.bitcoin/regtest
bitcoind
echo "Waiting for 5 secs for Bitcoin Demon to Initialize..."
sleep 5
