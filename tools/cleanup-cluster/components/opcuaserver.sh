#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm opcuaserver.sh"

NAMESPACE="azure-iot-operations"

echo ""
echo "Deleting all opcuaservers in namespace: $NAMESPACE..."
# Get all opcuaserver names in the namespace and remove the finalizers
kubectl get opcuaservers -n $NAMESPACE -o json | jq -r '.items[].metadata.name' | while read OPCUA_SERVER_NAME; do
    kubectl patch opcuaserver "$OPCUA_SERVER_NAME" -n $NAMESPACE -p '{"metadata":{"finalizers":[]}}' --type=merge
done

kubectl delete opcuaserver --all

echo ""
kubectl get opcuaserver -A

echo ""
echo "Deleting all opcua pipelines in namespace: $NAMESPACE..."
# Get all pipeline names in the namespace and remove the finalizers
kubectl get pipelines -n $NAMESPACE -o json | jq -r '.items[].metadata.name' | while read OPCUA_PIPELINE_NAME; do
    kubectl patch pipeline "$OPCUA_PIPELINE_NAME" -n $NAMESPACE -p '{"metadata":{"finalizers":[]}}' --type=merge
done

kubectl delete pipeline --all

echo ""
kubectl get pipeline -A
