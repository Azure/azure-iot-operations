#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm clusterrolebinding.sh"

# Old unprefixed clusterrolebinding
kubectl delete clusterrolebinding azedge-dmqtt-health-manager
kubectl delete clusterrolebinding azedge-dmqtt-token-review
kubectl delete clusterrolebinding azedge-e4k-operator

# Old bluefin and symphony clusterrolebinding
kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep bluefin-)
kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep symphony-)

# All AIO clusterrolebinding
kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep aio- | awk '{print $1}')

echo ""
kubectl get clusterrolebinding -A
