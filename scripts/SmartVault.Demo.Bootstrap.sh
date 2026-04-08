#####################################
# Using bitcoind and bitcoin-cli 
# as much as possible to demonstrate 
# the Layer 2 SmartVaults protocol
# and Hybrid Custody
#####################################

bitcoin-cli -named createwallet wallet_name="POC" descriptors=false >/dev/null 2>&1

echo "-------------"
echo "Bootstrapping Sentinels (co-signers)"
echo "-------------"

#Sentinel - Keys

#SentinelPriv="cS71P5KPZbgGYhkXfTomFNYxq2NRccQb8Zkw3XEQkMVnQdSvAYQn"
#SentinelPub="03cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b"

declare -a SentinelIDs
declare -a SentinelRatings
declare -a SentinelARTs
declare -a SentinelAddresses
declare -a SentinelPrivs
declare -a SentinelPubs

echo "-------------"
echo "Generating Sentinel 1: TrustMax's Credentials"
echo "-------------"

SentinelIDs+=("TrustMax")
SentinelRatings+=("4.0")
SentinelARTs+=("42 mins")
SentinelAddresses+=("$(bitcoin-cli getnewaddress)")
SentinelPrivs+=("$(bitcoin-cli dumpprivkey "${SentinelAddresses[0]}")")
SentinelPubs+=("$(bitcoin-cli getaddressinfo "${SentinelAddresses[0]}" | jq -r .pubkey)")

# echo "TrustMax's Private Key: ${SentinelPrivs[0]}"
echo "TrustMax's Public Key: ${SentinelPubs[0]}"
echo "TrustMax's Address: ${SentinelAddresses[0]}"

echo "-------------"
echo "Generating Sentinel 2: BlueOrion's Credentials"
echo "-------------"

SentinelIDs+=("BlueOrion")
SentinelRatings+=("5.0")
SentinelARTs+=("23 mins")
SentinelAddresses+=("$(bitcoin-cli getnewaddress)")
SentinelPrivs+=("$(bitcoin-cli dumpprivkey "${SentinelAddresses[1]}")")
SentinelPubs+=("$(bitcoin-cli getaddressinfo "${SentinelAddresses[1]}" | jq -r .pubkey)")


# echo "BlueOrion's Private Key: ${SentinelPrivs[1]}"
echo "BlueOrion's Public Key: ${SentinelPubs[1]}"
echo "BlueOrion's Address: ${SentinelAddresses[1]}"

echo "-------------"
echo "Generating Sentinel 3: EuroCrypt's Credentials"
echo "-------------"

SentinelIDs+=("EuroCrypt")
SentinelRatings+=("4.5")
SentinelARTs+=("34 mins")
SentinelAddresses+=("$(bitcoin-cli getnewaddress)")
SentinelPrivs+=("$(bitcoin-cli dumpprivkey "${SentinelAddresses[2]}")")
SentinelPubs+=("$(bitcoin-cli getaddressinfo "${SentinelAddresses[2]}" | jq -r .pubkey)")

# echo "EuroCrypt's Private Key: ${SentinelPrivs[2]}"
echo "EuroCrypt's Public Key: ${SentinelPubs[2]}"
echo "EuroCrypt's Address: ${SentinelAddresses[2]}"

echo "-------------"
echo "Sentinels are ready!"
echo "Lets initialize your credentials..."
echo "-------------"

read -n 1 -s -r -p "Press any key to generate a key pair for you..."
echo ""

#User - Keys

#UserPriv="cUrRAGYGV9Lj7yk7qFMZxxVeFTFqgt6BuJheb4EgVMafHef8f9p9"
#UserPub="023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416"

clear; echo ""
echo "-------------"
echo "Generating User's Priv-Pub-Addr"
echo "-------------"

UserAdrs=$(bitcoin-cli getnewaddress)
UserPriv=$(bitcoin-cli dumpprivkey "$UserAdrs")
UserPub=$(bitcoin-cli getaddressinfo "$UserAdrs" | jq -r .pubkey)

echo "Private Key: $UserPriv"
echo "Public Key: $UserPub"
echo "Address: $UserAdrs"

echo "-------------"

read -n 1 -s -r -p "Press any key to continue..."
echo ""

#####################################

echo "-------------"
echo "Generating blocks to bootstrap Bitcoin RegTest Blockchain"
echo "-------------"

bitcoin-cli generatetoaddress 101 "$UserAdrs" >/dev/null 2>&1
#bitcoin-cli importaddress "$UserAdrs"
echo "Done"