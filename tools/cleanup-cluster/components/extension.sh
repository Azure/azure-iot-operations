#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm extension.sh"

timeoutSeconds=180

echo ""
echo "Deleting Arc extensions..."

az k8s-extension list -g $1 -c $2 -t connectedClusters | jq -r '.[] | select(.extensionType | startswith("microsoft.iotoperations") or startswith("microsoft.deviceregistry.assets") or startswith("microsoft.azurekeyvaultsecretsprovider")) | .name' | while read -r extension_name; do
    echo "Force deleting arc extension: $extension_name"
    timeout $timeoutSeconds az k8s-extension delete -g $1 -c $2 -t connectedClusters -n "$extension_name" --yes
    az k8s-extension delete -g $1 -c $2 -t connectedClusters -n "$extension_name" --yes --force
done

# Bluefin
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n bluefin --yes --force

# E4K
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n data-plane --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n e4k --yes --force

# ADR
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n adr --yes --force

echo ""
az k8s-extension list -g $1 -c $2 -t connectedClusters -o table
