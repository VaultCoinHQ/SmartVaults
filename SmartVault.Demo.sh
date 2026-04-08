#!/bin/bash

script_name=$(basename "$0")
echo "Logging all output to logs/$script_name.log"

exec &> >(tee "logs/$script_name.log")

clear; echo ""

echo "-------------"
echo "This POC uses proprietary technologies"
echo "strictly for demonstration purposes only!"
echo "Patents: 11200568(US), 3830778A1(EU), and others."
echo "More Info: https://www.coinvault.tech/patents/"
echo "-------------"
echo ""
read -n 1 -s -r -p "Press any key to continue..."
echo ""

#####################################

source scripts/SmartVault.Demo.Initialize_RegTest_Network.sh

#####################################

clear; echo ""

source scripts/SmartVault.Demo.Bootstrap.sh

#####################################

while true
do

#####################################

source scripts/SmartVault.Demo.Setup.sh

#####################################

echo "Vault Balance: $(bitcoin-cli listunspent 1 9999999 "[\"$DepositTxOutputAddress\"]" | jq '[.[].amount] | add') BTC"

# Define your default choice
default=1

echo "-------------"
echo "What do you want to do next?"
echo "1) Spend with your private-key from the Vault"
echo "2) Initiate Recovery as you lost your private-key / Initiate Inheritance Flow"
echo "3) Initiate Override and Recovery as you suspect your private-keys are stolen"
echo "-----------------"

# Prompt the user
read -p "Select an option [1-3] (Default: $default): " choice

# Handle the default value if they just hit Enter
choice=${choice:-$default}

# Use 'case' to process the choice
case "$choice" in
    1)
        source scripts/SmartVault.Demo.Spend_Using_Option_1.sh #self spend
        ;;
    2)
        source scripts/SmartVault.Demo.Recovery_Using_Option_2.sh #recovery when you private-keys are lost
        ;;
    3)
        source scripts/SmartVault.Demo.Recovery_Using_Option_3.sh #recovery when private-keys are stolen
        ;;
    *)
        echo "Invalid selection '$choice'. Going with default option (1)."
        # Put your default action code here or call the script again
        ;;
esac

echo "-----------------"
echo "Check the source code and log here logs/$script_name.log"
echo "for a clear explanation of whats happening under the hood!"
echo "-----------------"

echo ""
read -n 1 -s -r -p "Press [Return] to continue or any other key to exit..." continue_choice
echo ""

if [[ -n "$continue_choice" ]]; then
    break
fi

#####################################

done

echo "-------------"
echo "Stopping Bitcoind"
echo "-------------"

#stop bitcoind
bitcoin-cli stop
