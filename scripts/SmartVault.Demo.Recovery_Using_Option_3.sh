#######################################
#
# Now the User is intiating Recovery in coordination 
# with his Sentinel as his or his Sentinel's private-key is
# presumed stolen or they see some adversarial activity on chain.
# 
# Ex. Unlock Tx (Provisional Tx) broadcasted by unknown entities
#
#######################################

echo "-------------"
echo "Simulating the recovery process by User in collaboration"
echo "with his Sentinel when his or his Sentinel's private-key is"
echo "presumed stolen or they see some adversarial activity on chain."
echo ""
echo "Ex. Unlock Tx (Provisional Tx) broadcasted by unknown entities"
echo "-------------"

echo "Balance in Recovery Addresss ($RecoveryAddress): $(bitcoin-cli listunspent 1 9999999 "[\"$RecoveryAddress\"]" | jq '[.[].amount] | add // 0') BTC"

read -n 1 -s -r -p "Press any key to start recovery..."
echo ""

echo "-------------"
echo "User signs the Partially Signed"
echo "Unlock Tx (Provisional Tx) received from Sentinel"
echo "with his Private Key"
echo "-------------"

echo "Done"

## Reusing the previously computed UserSignatureProv to reduce 
## code redundancy for this POC

echo "-------------"
echo "User's Private Key Generated Signature for Unlock Tx (Provisional Tx):"
echo "-------------"

echo $UserSignatureProv

echo "-------------"
echo "Fully Signed Unlock Tx (Provisional Tx):"
echo "-------------"

ProvTxSigned=$(python3 helpers/add_witness.py $ProvTx $SentinelSignatureProv $UserSignatureProv $DepositTxRedeemScript)
echo $ProvTxSigned

echo "-------------"
echo "Checking Fully Signed Unlock Tx (Provisional Tx):"
echo "-------------"

bitcoin-cli decoderawtransaction "$ProvTxSigned"

ProvTxId=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq -r '.txid')
ProvTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq '.vout[0] | .scriptPubKey.hex')
ProvTxAmount=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq '.vout[0] | .value')

#######################################
#
# User will broadcast Unlock Tx (ProvTx)
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

#########################################
#
# User will create a Recovery Tx
# to complete recovery
# 
#########################################

echo "-------------"
echo "Simulating Recovery by User using" 
echo "*** Option 3 *** of Unlock Tx (Provisonal Tx)"
echo "(Both User and Sentinel have to sign the recovery Tx)"
echo "-------------"

echo "Recovery Process - Start"

echo "-------------"
echo "User creates the Recovery Tx"
echo "-------------"

###########
fee=0.001
amount=$(echo "scale=8; $amount - $fee" | bc)

read -r -d '' RecovTxInputs <<-EOM
    [
        {
            "txid": "$ProvTxId",
            "vout": 0
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
echo "Simulating the transfer of Unsigned Recovery Tx"
echo "from User to Sentinel!"
echo "-------------"

echo "[U] --> Unsigned Provisional Tx --> [S]"

echo "-------------"
echo "Sentinel Signs the Recovery Tx"
echo "-------------"

SentinelSignatureRecov=$(python3 helpers/sign_tx.py $RecovTx 0 $ProvTxAmount $ProvTxRedeemScript $SentinelPriv SIGHASH_ALL True)

echo "-------------"
echo "Recovery Tx - Sentinel's Signature"
echo "-------------"
echo $SentinelSignatureRecov

echo "-------------"
echo "Simulating the transfer of Partially Signed Recovery Tx"
echo "from Sentinel to User!"
echo "-------------"

echo "[S] --> Partially Signed Provisional Tx --> [U]"

echo "-------------"
echo "User Signs the Recovery Tx"
echo "-------------"

UserSignatureRecov=$(python3 helpers/sign_tx.py $RecovTx 0 $ProvTxAmount $ProvTxRedeemScript $UserPriv SIGHASH_ALL True)

echo "-------------"
echo "Recovery Tx - User's Signature"
echo "-------------"
echo $UserSignatureRecov

echo "-------------"
echo "Fully Signed Recovery Tx:"
echo "-------------"

# [Customize This in accordance with Option]
RecovTxSigned=$(python3 helpers/add_witness.py $RecovTx $SentinelSignatureRecov $UserSignatureRecov 02 $ProvTxRedeemScript)

echo $RecovTxSigned

echo "-------------"
echo "Checking Fully Signed Recovery Tx:"
echo "-------------"

bitcoin-cli decoderawtransaction "$RecovTxSigned"

RecovTxID=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq -r '.txid')
RecovTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq '.vout[0] | .scriptPubKey.hex')

#######################################
#
# User will broadcast RecovTx
# to complete recovery
#
#######################################

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
