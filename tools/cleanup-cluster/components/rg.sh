#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm rg.sh"

timeoutSeconds=600

echo ""
echo "Listing all resources in resource group: $1..."
az resource list -g $1 -o table

echo ""
echo "Deleting entire resource group: $1..."
echo "Continue?"
echo "Press ENTER to continue or press Ctrl+C to exit..."
read input

echo ""
echo "Deleting resource group: $1..."
timeout $timeoutSeconds az group delete --name $1 --yes
