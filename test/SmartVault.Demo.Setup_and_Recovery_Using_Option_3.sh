#!/bin/bash

script_name=$(basename "$0")
echo "Logging all output to logs/$script_name.log"

read -n 1 -s -r -p "Press any key to continue..."
echo ""

exec &> >(tee "logs/$script_name.log")

#####################################

source scripts/SmartVault.Demo.Initialize_RegTest_Network.sh

#####################################

source scripts/SmartVault.Demo.Setup.sh

#######################################

read -n 1 -s -r -p "Press any key to continue..."
echo ""

#######################################

source scripts/SmartVault.Demo.Recovery_Using_Option_3.sh
