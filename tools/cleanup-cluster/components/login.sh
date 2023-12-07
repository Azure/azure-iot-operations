#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm login.sh"


az login --use-device-code --output none
az account set --subscription $1

echo ""
echo "Your current subscription is: $1"
az account show