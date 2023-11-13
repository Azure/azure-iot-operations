#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm namespace.sh"

echo ""
kubectl delete namespace alice-springs
kubectl delete namespace alice-springs-solution
kubectl delete namespace azure-iot-operations
kubectl delete namespace azure-iot-operations-solution
kubectl delete namespace symphony-k8s-system
kubectl delete namespace custom-location-a

echo ""
kubectl get namespace -A