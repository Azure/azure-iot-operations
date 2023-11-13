#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm extension.sh"

echo ""
echo "Deleting Arc extensions..."

# AIO
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n azure-iot-operations --yes --force

# Symphony
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n alice-springs --yes --force

# Akri
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n akri --yes --force

# Bluefin
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n processor --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n bluefin --yes --force

# E4K
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n data-plane --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n e4k --yes --force

# MQ
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n mq --yes --force

# OPCUA
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n opc-ua-broker --yes --force

# ADR
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n assets --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n adr --yes --force

# Secret
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n akvsecretsprovider --yes --force

# Network
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n layered-networking --yes --force

echo ""
az k8s-extension list -g $1 -c $2 -t connectedClusters -o table
