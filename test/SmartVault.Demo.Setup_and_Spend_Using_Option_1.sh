#!/bin/bash

script_name=$(basename "$0")
echo "Logging all output to logs/$script_name.log"

read -n 1 -s -r -p "Press any key to continue..."
echo ""

exec &> >(tee "logs/$script_name.log")

#####################################

source scripts/SmartVault.Demo.Initialize_RegTest_Network.sh

#####################################

clear; echo ""

source scripts/SmartVault.Demo.Bootstrap.sh

#####################################

source scripts/SmartVault.Demo.Setup.sh

#######################################

read -n 1 -s -r -p "Press any key to continue..."
echo ""

#######################################

source scripts/SmartVault.Demo.Spend_Using_Option_1.sh

#######################################

echo "-------------"
echo "Stopping Bitcoind"
echo "-------------"

#stop bitcoind
bitcoin-cli stop

echo "-----------------"
echo "Check the source code and log here logs/$script_name.log"
echo "for a clear explanation of whats happening under the hood!"
echo "-----------------"
