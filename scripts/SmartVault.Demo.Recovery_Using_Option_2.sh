#######################################
#
# Now the User is intiating Recovery
# in coordination with Sentinel
# as his private-key is lost
# (Requires only Sentinel's private-key)
#
#######################################

echo "-------------"
echo "Simulating the recovery process by Sentinel"
echo "as your private-key is lost or is executing"
echo "your inheritance mandate!"
echo ""
echo "(Requires only Sentinel's private-key)"
echo "-------------"

echo "Balance in Recovery Addresss ($RecoveryAddress): $(bitcoin-cli listunspent 1 9999999 "[\"$RecoveryAddress\"]" | jq '[.[].amount] | add // 0') BTC"


read -n 1 -s -r -p "Press any key to start recovery..."
echo ""

echo "-------------"
echo "Sentinel signs the Partially Signed"
echo "Unlock Tx (Provisional Tx) received from User"
echo "with its Private Key"
echo "-------------"

echo "Done"

## Reusing the previously computed SentinelSignatureProv to reduce 
## code redundancy for this Demo

echo "-------------"
echo "Sentinel's Private Key Generated Signature for Unlock Tx (Provisional Tx):"
echo "-------------"

echo $SentinelSignatureProv

echo "-------------"
echo "Fully Signed Unlock Tx (Provisional Tx):"
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
# Sentinel will broadcast ProvTx
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
bitcoin-cli generatetoaddress 1 "$SentinelAddress" >/dev/null 2>&1

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

echo "-------------"
echo "Everyone including you can monitor the Vault and see the Unlock Tx on-chain"
echo "and you can initiate recovery using Option 1 (spend with your private-key)"
echo "if this Recovery was not requested by you and you suspect foul pay."
echo "-------------"

read -n 1 -s -r -p "Press any key to continue with recovery..."
echo ""

#########################################
#
# Sentinel will create a Recovery Tx
# to complete recovery
# 
#########################################

echo "-------------"
echo "Simulating Recovery by Sentinel using" 
echo "*** Option 2 *** of Unlock Tx (Provisional Tx)"
echo "(Using just Sentinel's Private Key)"
echo "-------------"

echo "Recovery Process - Start"

echo "-------------"
echo "Sentinel creates the Recovery Tx"
echo "-------------"

###########
fee=0.001
amount=$(echo "scale=8; $amount - $fee" | bc)

read -r -d '' RecovTxInputs <<-EOM
    [
        {
            "txid": "$ProvTxId",
            "vout": 0,
            "sequence": $SentinelDelay
        }
    ]
EOM

read -r -d '' RecovTxOutputs <<-EOM
    [
        {
            "$RecoveryAddress": $amount
        }
    ]
EOM

RecovTx=$(bitcoin-cli createrawtransaction "$RecovTxInputs" "$RecovTxOutputs")
echo "Done"

echo "-------------"
echo "Unsigned Recovery Tx"
echo "-------------"

echo $RecovTx

echo "-------------"
echo "Checking Unsigned Recovery Tx"
echo "-------------"

bitcoin-cli decoderawtransaction "$RecovTx"

echo "-------------"
echo "Sentinel Signs the Recovery Tx"
echo "-------------"

SentinelSignatureRecov=$(python3 helpers/sign_tx.py $RecovTx 0 $ProvTxAmount $ProvTxRedeemScript $SentinelPriv SIGHASH_ALL True)

echo "-------------"
echo "Recovery Tx - Sentinel's Signature"
echo "-------------"
echo $SentinelSignatureRecov

echo "-------------"
echo "Fully Signed Recovery Tx:"
echo "-------------"

# [Customize This in accordance with Option]
RecovTxSigned=$(python3 helpers/add_witness.py $RecovTx $SentinelSignatureRecov 01 $ProvTxRedeemScript)

echo $RecovTxSigned

echo "-------------"
echo "Checking Fully Signed Recovery Tx:"
echo "-------------"

bitcoin-cli decoderawtransaction "$RecovTxSigned"

RecovTxID=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq -r '.txid')
RecovTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq '.vout[0] | .scriptPubKey.hex')

#######################################
#
# Sentinel will broadcast RecovTx
# to intiative recovery
#
#######################################

echo "-------------"
echo "Creating Blocks to satisfy Timelocks"
echo "-------------"

#Create blocks to unlock the timelock [Customize This in accordance with Option]
bitcoin-cli generatetoaddress $SentinelDelay "$SentinelAddress" >/dev/null 2>&1

echo "$SentinelDelay Blocks Created!"

echo "-------------"
echo "Vaildating Recovery Tx"
echo "-------------"

bitcoin-cli testmempoolaccept "[ \"$RecovTxSigned\" ]"

echo "-------------"
echo "Broadcasting Recovery Tx"
echo "-------------"

bitcoin-cli sendrawtransaction "$RecovTxSigned" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Generating Block to confirm Recovery Tx"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$SentinelAddress" >/dev/null 2>&1
echo "Done"

echo "-------------"
echo "Recovery Tx Block ID:"
echo "-------------"
RecovTxBlock=$(bitcoin-cli getbestblockhash)
echo $RecovTxBlock

echo "-------------"
echo "Confirmed Recovery Tx"
echo "-------------"

bitcoin-cli getrawtransaction "$RecovTxID" true "$RecovTxBlock"

clear; echo ""

echo "-------------"
echo "***Recovery Complete!***"
echo "-------------"

echo "Balance in Recovery Addresss ($RecoveryAddress): $(bitcoin-cli listunspent 1 9999999 "[\"$RecoveryAddress\"]" | jq '[.[].amount] | add // 0') BTC"

##############################
