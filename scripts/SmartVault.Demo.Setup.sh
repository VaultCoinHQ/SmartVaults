#!/bin/bash

#####################################

unspent=$(bitcoin-cli listunspent 1 9999999 "[\"$UserAdrs\"]")

utxo_txid_1=$(echo $unspent | jq -r '.[0] | .txid')
utxo_vout_1=$(echo $unspent | jq -r '.[0] | .vout')
utxo_amount_1=$(echo $unspent | jq -r '.[0] | .amount')

clear; echo ""

# echo "Balance: $(bitcoin-cli listunspent 1 9999999 "[\"$UserAdrs\"]" | jq '[.[].amount] | add') BTC"
echo "Balance: $utxo_amount_1 BTC"

read -n 1 -s -r -p "Press any key to start Hybrid Custody Vault setup..."
echo ""

# Choose your Sentinel

echo "-------------"
echo "Choose your Sentinel:"
echo "-------------"

for i in "${!SentinelIDs[@]}"; do
    echo "$((i + 1))) ${SentinelIDs[$i]} • Rating: ${SentinelRatings[$i]} ★ • Avg. Response Time: ${SentinelARTs[$i]}"
done

echo "-------------"
read -p "Select [1-${#SentinelIDs[@]}] (Default: 1): " SentinelChoice

SentinelChoice=${SentinelChoice:-1}

if ! [[ "$SentinelChoice" =~ ^[1-9][0-9]*$ ]] || (( SentinelChoice < 1 || SentinelChoice > ${#SentinelIDs[@]} )); then
    echo "Invalid selection '$SentinelChoice'. Going with default Sentinel (1)."
    SentinelChoice=1
fi

SelectedSentinelIndex=$((SentinelChoice - 1))
SentinelID="${SentinelIDs[$SelectedSentinelIndex]}"
SentinelRating="${SentinelRatings[$SelectedSentinelIndex]}"
SentinelART="${SentinelARTs[$SelectedSentinelIndex]}"
SentinelAddress="${SentinelAddresses[$SelectedSentinelIndex]}"
SentinelPriv="${SentinelPrivs[$SelectedSentinelIndex]}"
SentinelPub="${SentinelPubs[$SelectedSentinelIndex]}"

clear; echo ""
echo "-------------"
echo "Selected Sentinel: $SentinelID • Rating: $SentinelRating ★ • Avg. Response Time: $SentinelART"
echo "-------------"
read -n 1 -s -r -p "Press any key to continue..."
echo ""

# Create Deposit Transaction

echo "-------------"
echo "Deposit Tx Redeem Script"
echo "-------------"

#####################################################################
# Deposit Transaction - Script / Smart Contract - Ivy Lang
#
# contract Deposit(
#   user: PublicKey,
#   sentinel: PublicKey,
#   val: Value
# ) 
# {
#   clause spend(userSig: Signature, sentinelSig: Signature) {
#     verify checkMultiSig([user, sentinel], [userSig, sentinelSig])
#     unlock val
#   }
# }
#####################################################################

#DepositTxRedeemScript="2103cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b21023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f41600547a547a527152ae"
DepositTxRedeemScript="21${SentinelPub}21${UserPub}00547a547a527152ae"

echo $DepositTxRedeemScript

echo "-------------"
echo "Checking Deposit Tx Redeem Script"
echo "-------------"

bitcoin-cli decodescript "$DepositTxRedeemScript"

# bitcoin-cli decodescript $DepositTxRedeemScript
# {
#   "asm": "03cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b 023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416 0 4 OP_ROLL 4 OP_ROLL 2 OP_2ROT 2 OP_CHECKMULTISIG",
#   "type": "nonstandard",
#   "p2sh": "2N67fe2umeVqEvKP9pDho7U44WFEB6qwSkf",
#   "segwit": {
#     "asm": "0 60ab4558df4445fdcae68eba8810c6febcae467e88e2a1ac0f1c2169d449a759",
#     "hex": "002060ab4558df4445fdcae68eba8810c6febcae467e88e2a1ac0f1c2169d449a759",
#     "reqSigs": 1,
#     "type": "witness_v0_scripthash",
#     "addresses": [
#       "bcrt1qvz452kxlg3zlmjhx36agsyxxl672u3n73r32rtq0rsskn4zf5avs0ye2zj"
#     ],
#     "p2sh-segwit": "2NEe9XKk3mDrc6FEZvoa19KGmE55bVpKb2L"
#   }
# }

DepositTxOutputAddress=$(bitcoin-cli decodescript "$DepositTxRedeemScript" | jq -r .segwit.address)

echo "-------------"
echo "Deposit Tx - Script to Address"
echo "-------------"

echo $DepositTxOutputAddress

fee=0.001
amount=$(echo "scale=8; $utxo_amount_1 - $fee" | bc)

read -r -d '' DepositTxInputs <<-EOM
    [
        {
            "txid": "$utxo_txid_1",
            "vout": $utxo_vout_1
        }
    ]
EOM

read -r -d '' DepositTxOutputs <<-EOM
    [
        {
            "$DepositTxOutputAddress": $amount
        }
    ]
EOM

bitcoin-cli importaddress "$DepositTxOutputAddress"

echo "-------------"
echo "Creating Unsigned Deposit Tx"
echo "-------------"

DepositTx=$(bitcoin-cli createrawtransaction "$DepositTxInputs" "$DepositTxOutputs")

echo "Done"

echo "-------------"
echo "Unsigned Deposit Tx"
echo "-------------"

echo $DepositTx

echo "-------------"
echo "Checking Unsigned Deposit Tx"
echo "-------------"

bitcoin-cli decoderawtransaction "$DepositTx"

echo "-------------"
echo "Signing the Deposit Tx"
echo "-------------"

DepositTxSigned=$(bitcoin-cli signrawtransactionwithkey "$DepositTx"  "[\"$UserPriv\"]" | jq -r '.hex')
echo "Done"

echo "-------------"
echo "Signed Deposit Tx"
echo "-------------"

echo $DepositTxSigned

echo "-------------"
echo "Checking Signed Deposit Tx"
echo "-------------"

bitcoin-cli decoderawtransaction "$DepositTxSigned"

DepositTxID=$(bitcoin-cli decoderawtransaction "$DepositTxSigned" | jq -r '.txid')
DepositTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$DepositTxSigned" | jq '.vout[0] | .scriptPubKey.hex')
DepositTxAmount=$(bitcoin-cli decoderawtransaction "$DepositTxSigned" | jq '.vout[0] | .value')

#####################################################################
# Unlock Tx (Provisional Tx) - Script / Smart Contract - Ivy Lang
#
# contract SmartVault(
#   user: PublicKey,
#   sentinel: PublicKey,
#   userDelay: Duration,
#   sentinelDelay: Duration,
#   val: Value
# ) 
# {  
#   /* Option : 1 [1000] */
#   clause User(userSig: Signature) {
#     verify checkSig(user, userSig)
#     verify older(userDelay)
#     unlock val
#   }
#   /* Option : 2 [5000] */
#   clause Sentinel(sentinelSig: Signature) {
#     verify checkSig(sentinel, sentinelSig)
#     verify older(sentinelDelay)
#     unlock val
#   }
#   /* Option : 3 */
#   clause MultiSig(userSig: Signature, sentinelSig: Signature) {
#     verify checkMultiSig([user, sentinel], [userSig, sentinelSig])
#     unlock val
#   }
# }
#####################################################################

clear; echo ""

echo "-------------"
echo "Your Vault has a 2-step Unlock and Spend process to transfer from it"
echo "and there is a mandatory yet configureable delay enforced between these"
echo "Unlock and Spend Transactions for every private-key/combination allowed"
echo "to spend from this Vault."
echo "-------------"

read -n 1 -s -r -p "Press any key to configure these delays and continue..."
echo ""

clear; echo ""

echo "-------------"
echo "Lets configure the on-chain delay / cooling period"
echo "for spending with your private-key from your Vault!"
echo ""
echo "This will give you time to react and initiate recovery"
echo "when your private-key or wallet backup (seed phrase) is stolen"
echo "and is used to unlock and potentially spend from your Vault."
echo "-------------"

default=1000; 
read -p "Enter delay in blocks or press [Return] to use default [$default]: " input; input=${input:-$default}; [[ "$input" =~ ^[0-9]+$ && "$((10#$input))" -gt 0 ]] && input=$((10#$input)) || { echo "Invalid input, using $default"; input=$default; }

UserDelay=$input
echo "Setting Option 1 (User Private-Key Only) Delay to $UserDelay"
UserDelayCoded=$(python3 helpers/number_coding.py --encode $UserDelay) #500=f401

clear; echo ""

echo "-------------"
echo "Now, lets configure the on-chain delay / cooling period" 
echo "for spending with the Sentinel private-key from your Vault!"
echo ""
echo "This is the delay your Sentinel has to wait before he can"
echo "transfer/recover from your Vault in case your private-key"
echo "is lost or for managing your inheritance."
echo ""
echo "PS: This is typically much longer than the previously set delay"
echo "and will give you time to react and override any spend attempt"
echo "by compromised/rogue Sentinels with just your private-key"
echo "eliminating counter-party risk in the Hybrid Custody Ecosystem."
echo "-------------"

default=5000; 
read -p "Enter delay in blocks or press [Return] to use default [$default]: " input; input=${input:-$default}; [[ "$input" =~ ^[0-9]+$ && "$((10#$input))" -gt 0 ]] && input=$((10#$input)) || { echo "Invalid input, using $default"; input=$default; }

if (( input <= UserDelay )); then
    echo "Sentinel Delay cannot be smaller than User Delay. Using $default"
    input=$default
fi

SentinelDelay=$input
echo "Setting Option 2 (Sentinel Private-Key Only) Delay to $SentinelDelay"
SentinelDelayCoded=$(python3 helpers/number_coding.py --encode $SentinelDelay) #2500=c409

# 1. Default Recovery Address
DefaultRecoveryAdrs=$(bitcoin-cli getnewaddress)

clear; echo ""

# 2. Prompt the user
echo "-------------"
echo "Now, lets configure the Recovery Address for your Vault!" 
echo ""
echo "Once your private-keys are lost or stolen, it is not"
echo "safe to recover your Vault to an address controlled by you"
echo "as we never know how deep the compromise is."
echo ""
echo "The best approach would be to temporarily transfer the coins in your"
echo "Vault to a custodial wallet address (Coinbase, Binance, etc.) and disable"
echo "withdrawls from it until you can create a new secure cold-storage wallet and Vault."
echo ""
echo "Alternatively, you can setup a new unused Hardware Wallet"
echo "with a new seed-phrase and store both the hardware wallet and"
echo "seed-phrase backup in a bank locker and use this wallet's address as Recovery Address!"
echo ""
echo "PS: Sentinels are bound by on-chain Staking/Slashing mechanics"
echo "to only sign Recovery transactions to this Preconfigured Recovery Address"
echo "as no user provided input can be trusted post compromise/setup!"
echo "-------------"
read -p "Enter Recovery Address or press [Return] to use default [$DefaultRecoveryAdrs]: " input

# 3. Apply default if input is empty
input=${input:-$DefaultRecoveryAdrs}

# 4. Validation: Check if the address looks remotely valid (not empty/too short)
# Most BTC addresses are at least 26 characters. 
if [[ ${#input} -ge 26 ]]; then
    RecoveryAddress=$input
    bitcoin-cli importaddress "$DefaultRecoveryAdrs"
else
    echo "Invalid address format. Falling back to default."
    RecoveryAddress=$DefaultRecoveryAdrs
fi

echo "Proceeding with Recovery Address: $RecoveryAddress"

echo "-------------"
echo "Unlock Tx (Provisional Tx) Redeem Script"
echo "-------------"

ProvTxRedeemScript="02${SentinelDelayCoded}02${UserDelayCoded}21${SentinelPub}21${UserPub}54795287637b757b757b7500547a547a527152ae67547a6375777b7cadb2755167777b757b7cadb275516868"

echo "Hex: $ProvTxRedeemScript"

echo "-------------"
echo "Checking Unlock Tx (Provisional Tx) Redeem Script"
echo "-------------"

bitcoin-cli decodescript "$ProvTxRedeemScript"

# Ref:
# bitcoin-cli decodescript $ProvTxRedeemScript
# {
#   "asm": "2500 500 03cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b 023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416 4 OP_PICK 2 OP_EQUAL OP_IF OP_ROT OP_DROP OP_ROT OP_DROP OP_ROT OP_DROP 0 4 OP_ROLL 4 OP_ROLL 2 OP_2ROT 2 OP_CHECKMULTISIG OP_ELSE 4 OP_ROLL OP_IF OP_DROP OP_NIP OP_ROT OP_SWAP OP_CHECKSIGVERIFY OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ELSE OP_NIP OP_ROT OP_DROP OP_ROT OP_SWAP OP_CHECKSIGVERIFY OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ENDIF OP_ENDIF",
#   "type": "nonstandard",
#   "p2sh": "2NALhW1somHP9ifDFc6YjzbTPfUB8dbgNuL",
#   "segwit": {
#     "asm": "0 20d29d4c1268eef833fd1d9a25fc2881dd36ab55c92e56f10a0e81b557e8ef95",
#     "hex": "002020d29d4c1268eef833fd1d9a25fc2881dd36ab55c92e56f10a0e81b557e8ef95",
#     "reqSigs": 1,
#     "type": "witness_v0_scripthash",
#     "addresses": [
#       "bcrt1qyrff6nqjdrh0svlarkdztlpgs8wnd264eyh9dug2p6qm24lga72srtvven"
#     ],
#     "p2sh-segwit": "2N63Rp9WJEvkVviV6Hbx1qmV7JaKv2jZAyU"
#   }
# }

echo "-------------"
echo "Unlock Tx (Provisional Tx) - Script to Address"
echo "-------------"

ProvTxOutputAddress=$(bitcoin-cli decodescript "$ProvTxRedeemScript" | jq -r .segwit.address)

echo $ProvTxOutputAddress

###########
fee=0.001
amount=$(echo "scale=8; $amount - $fee" | bc)

read -r -d '' ProvTxInputs <<-EOM
    [
        {
            "txid": "$DepositTxID",
            "vout": 0
        }
    ]
EOM

read -r -d '' ProvTxOutputs <<-EOM
    [
        {
            "$ProvTxOutputAddress": $amount
        }
    ]
EOM

echo "-------------"
echo "Creating Unsigned Unlock Tx (Provisional Tx)"
echo "-------------"

ProvTx=$(bitcoin-cli createrawtransaction "$ProvTxInputs" "$ProvTxOutputs")

echo $ProvTx

echo "-------------"
echo "Checking Unsigned Unlock Tx Created by User"
echo "-------------"

bitcoin-cli decoderawtransaction "$ProvTx"

echo "-------------"
echo "Simulating the transfer of Unsigned Unlock Tx (Provisional Tx) copy"
echo "to Sentinel!"
echo "-------------"

echo "[U] --> Unsigned Unlock Tx (Provisional Tx) --> [S]"

echo "-------------"
echo "Sentinel signs the Unsigned Unlock Tx (Provisional Tx)"
echo "with his Private Key"
echo "-------------"

SentinelSignatureProv=$(python3 helpers/sign_tx.py $ProvTx 0 $DepositTxAmount $DepositTxRedeemScript $SentinelPriv SIGHASH_ALL True)

echo "-------------"
echo "Unlock Tx (Provisional Tx) - Sentinel's Signature"
echo "-------------"

echo $SentinelSignatureProv

echo "-------------"
echo "Simulating the transfer of Partially Signed Unlock Tx (Provisional Tx)"
echo "to User!"
echo "-------------"

echo "[S] --> Partially Signed Unlock Tx (Provisional Tx) --> [U]"

####################################

echo "-------------"
echo "User signs the Unsigned Unlock Tx (Provisional Tx)"
echo "with his Private Key"
echo "-------------"

UserSignatureProv=$(python3 helpers/sign_tx.py $ProvTx 0 $DepositTxAmount $DepositTxRedeemScript $UserPriv SIGHASH_ALL True)

echo "-------------"
echo "Unlock Tx (Provisional Tx) - User Signature"
echo "-------------"

echo $UserSignatureProv

echo "-------------"
echo "Simulating the transfer of Partially Signed Unlock Tx (Provisional Tx) copy"
echo "to Sentinel!"
echo "-------------"

echo "[U] --> Partially Signed Provisional Tx --> [S]"

#######################################
#
# User will broadcast DepositTx
# after receiving the
# Partially Signed Prov. Tx with
# Sentinel's signature already added to it
#
#######################################

echo "-------------"
echo "User signs & broadcasts the Deposit Tx"
echo "after receiving the Partially signed Unlock Tx (Provisional Tx)"
echo "-------------"

#Broadcast DepositTx
bitcoin-cli sendrawtransaction "$DepositTxSigned" #>/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Generating Block to confirm the Deposit Tx"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$SentinelAddress" >/dev/null 2>&1

DepositTxBlock=$(bitcoin-cli getbestblockhash)

echo "Deposit Tx Block: $DepositTxBlock"

echo "-------------"
echo "Confirmed Deposit Tx"
echo "-------------"

bitcoin-cli getrawtransaction "$DepositTxID" true "$DepositTxBlock"

clear;echo ""

echo "-------------"
echo "*** Smart Vault Setup Complete! ***"
echo "-------------"

#####################################

echo "You are now assured of your"
echo "Bitcoin's safety and security"
echo "as your Bitcoin is now in Joint Custody and"
echo "rest everything is managed using the"
echo "Partially Signed Unlock Txs (Provisional Txs) with you"
echo "and your Sentinel after the Smart Vault setup is complete!"
echo "-------------"
