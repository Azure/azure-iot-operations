#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm namespace.sh"

timeoutSeconds=60

delete_namespace() {
    namespace=$1
    echo ""
    echo "Deleting namespace $namespace..."
    timeout $timeoutSeconds kubectl delete namespace $namespace
    if [ $? -eq 124 ]; then
        kubectl get namespace -A
        echo "Deleting namespace $namespace timed out. Exiting..."
        exit 1
    fi
}

delete_namespace "alice-springs"
delete_namespace "alice-springs-solution"
delete_namespace "azure-iot-operations-solution"
delete_namespace "symphony-k8s-system"
delete_namespace "custom-location-a"
delete_namespace "azure-iot-operations"

echo ""
kubectl get namespace -A