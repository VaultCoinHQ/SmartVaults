#!/bin/bash

#######################################
#
# Now the User is terminating the Vault.
# Baseline self-custody mechanics.
# (Requires only User's private-key)
#
#######################################

echo "-------------"
echo "Initiating Vault termination(spend)."
echo "Baseline self-custody mechanics!" 
echo "(Requires only User's private-key)"
echo "-------------"

read -n 1 -s -r -p "Press any key to start unlock and spend..."
echo ""

echo "-------------"
echo "User signs the Partially Signed"
echo "Unlock Tx (Provisional Tx) received from Sentinel"
echo "with his Private Key"
echo "-------------"

## Reusing the previously computed UserSignatureProv to reduce 
## code redundancy for this demo

echo "-------------"
echo "User's Private Key Generated Signature for Unlock Tx (Provisional Tx):"
echo "-------------"

echo $UserSignatureProv

echo "-------------"
echo "Fully Signed Unlock Tx (Provisional Tx) :"
echo "-------------"

ProvTxSigned=$(python3 helpers/add_witness.py $ProvTx $SentinelSignatureProv $UserSignatureProv $DepositTxRedeemScript)
echo $ProvTxSigned

echo "-------------"
echo "Checking Fully Signed Unlock Tx (Provisional Tx) :"
echo "-------------"

bitcoin-cli decoderawtransaction "$ProvTxSigned"

ProvTxId=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq -r '.txid')
ProvTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq '.vout[0] | .scriptPubKey.hex')
ProvTxAmount=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq '.vout[0] | .value')

#######################################
#
# User will broadcast ProvTx
# to intiative recovery
#
#######################################

echo "-------------"
echo "Vaildate Fully Signed Unlock Tx (Provisional Tx)"
echo "-------------"

#Test ProvTx
bitcoin-cli testmempoolaccept "[ \"$ProvTxSigned\" ]"

echo "-------------"
echo "Broadcast Fully Signed Unlock Tx (Provisional Tx)"
echo "-------------"

#Broadcast ProvTx
bitcoin-cli sendrawtransaction "$ProvTxSigned" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Generating Block to confirm Unlock Tx (Provisional Tx)"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$UserAdrs" >/dev/null 2>&1

echo "Done"

echo "-------------"
echo "Unlock Tx (Provisional Tx) Block:"
echo "-------------"

ProvTxBlock=$(bitcoin-cli getbestblockhash)
echo $ProvTxBlock

echo "-------------"
echo "Confirmed Unlock Tx (Provisional Tx)"
echo "-------------"

bitcoin-cli getrawtransaction "$ProvTxId" true "$ProvTxBlock"

#########################################
#
# User will create a Spend Tx
# to complete Vault termination
# 
#########################################

clear; echo ""

echo "-------------"
echo "Simulating Spend by User using" 
echo "*** Option 1 *** of Unlock Tx (Provisional Tx)"
echo "(Using just User's Private Key)"
echo "-------------"

echo "Spend Process - Start"

echo "-------------"
echo "Create the Spend Tx"
echo "-------------"

# 1. Default destimation address
DefaultToAdrs=$(bitcoin-cli getnewaddress)

# 2. Prompt the user
echo "Please enter the destination Bitcoin address."
read -p "Enter Address or press [Return] to use default [$DefaultToAdrs]: " input

# 3. Apply default if input is empty
input=${input:-$DefaultToAdrs}

# 4. Validation: Check if the address looks remotely valid (not empty/too short)
# Most BTC addresses are at least 26 characters. 
if [[ ${#input} -ge 26 ]]; then
    TargetAddress=$input
    bitcoin-cli importaddress "$DefaultToAdrs"
else
    echo "Invalid address format. Falling back to default."
    TargetAddress=$DefaultToAdrs
fi

echo "Proceeding with address: $TargetAddress"

fee=0.001
amount=$(echo "scale=8; $amount - $fee" | bc)

# [Customize this in accordance with Option]
read -r -d '' SpendTxInputs <<-EOM
    [
        {
            "txid": "$ProvTxId",
            "vout": 0,
            "sequence": $UserDelay
        }
    ]
EOM

read -r -d '' SpendTxOutputs <<-EOM
    [
        {
            "$TargetAddress": $amount
        }
    ]
EOM

SpendTx=$(bitcoin-cli createrawtransaction "$SpendTxInputs" "$SpendTxOutputs")
echo "Done"

echo "-------------"
echo "Unsigned Spend Tx"
echo "-------------"

echo $SpendTx

echo "-------------"
echo "Checking Unsigned Spend Tx"
echo "-------------"

bitcoin-cli decoderawtransaction "$SpendTx"

echo "-------------"
echo "User Signs the Spend Tx"
echo "-------------"

UserSignatureSpend=$(python3 helpers/sign_tx.py $SpendTx 0 $ProvTxAmount $ProvTxRedeemScript $UserPriv SIGHASH_ALL True)

echo "-------------"
echo "Spend Tx - User's Signature"
echo "-------------"
echo $UserSignatureSpend

echo "-------------"
echo "Fully Signed Spend Tx:"
echo "-------------"

# [Customize This in accordance with Option]
# Do not use "00" to select the option for recovery. Use "0"
# https://bitcoin.stackexchange.com/questions/122822/why-is-my-p2wsh-op-if-notif-argument-not-minimal
SpendTxSigned=$(python3 helpers/add_witness.py $SpendTx $UserSignatureSpend 0 $ProvTxRedeemScript)

echo $SpendTxSigned

echo "-------------"
echo "Checking Fully Signed Spend Tx:"
echo "-------------"

bitcoin-cli decoderawtransaction "$SpendTxSigned"

SpendTxID=$(bitcoin-cli decoderawtransaction "$SpendTxSigned" | jq -r '.txid')
SpendTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$SpendTxSigned" | jq '.vout[0] | .scriptPubKey.hex')

#######################################
#
# User will broadcast SpendTx
# to intiative spend/treansfer
#
#######################################

echo "-------------"
echo "Creating Blocks to satisfy Timelocks"
echo "-------------"

#Create blocks to unlock the timelock [Customize This in accordance with Option]
bitcoin-cli generatetoaddress $UserDelay "$UserAdrs" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Vaildating Spend Tx"
echo "-------------"

bitcoin-cli testmempoolaccept "[ \"$SpendTxSigned\" ]"

echo "-------------"
echo "Broadcasting Spend Tx"
echo "-------------"

bitcoin-cli sendrawtransaction "$SpendTxSigned" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Generating Block to confirm Spend Tx"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$UserAdrs" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Spend Tx Block ID:"
echo "-------------"
RecovTxBlock=$(bitcoin-cli getbestblockhash)
echo $RecovTxBlock

echo "-------------"
echo "Confirmed Spend Tx"
echo "-------------"

bitcoin-cli getrawtransaction "$SpendTxID" true "$RecovTxBlock"

echo "-------------"
echo "*** Spend/Transfer Complete! ***"
echo "-------------"

echo "Balance in Destination Address ($TargetAddress): $(bitcoin-cli listunspent 1 9999999 "[\"$TargetAddress\"]" | jq '[.[].amount] | add // 0') BTC"

##############################

echo "-------------"
echo "Stopping Bitcoind"
echo "-------------"

#stop bitcoind
bitcoin-cli stop
