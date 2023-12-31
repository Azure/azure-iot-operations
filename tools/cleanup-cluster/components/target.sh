#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm target.sh"

# Clean up finalizers to allow deletion of targets
kubectl -n azure-iot-operations get -o name targets.orchestrator.iotoperations.azure.com | xargs -I {} kubectl -n azure-iot-operations patch {} -p '{"metadata":{"finalizers":[]}}' --type=merge

echo ""
kubectl get target -A
