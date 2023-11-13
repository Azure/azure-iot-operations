#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm crd.sh"

echo ""
echo "Deleting all Alice Springs' CRDs in current k8s cluster..."
echo ""

timeoutSeconds=40

# AKRI
kubectl delete crd instances.akri.sh
kubectl delete crd configurations.akri.sh

# ADR
kubectl delete crd assets.deviceregistry.microsoft.com
kubectl delete crd assetendpointprofiles.deviceregistry.microsoft.com

# E4I
kubectl delete crd applications.e4i.microsoft.com 
kubectl delete crd assets.e4i.microsoft.com
kubectl delete crd assettypes.e4i.microsoft.com
kubectl delete crd modules.e4i.microsoft.com
kubectl delete crd moduletypes.e4i.microsoft.com

# E4K
kubectl get crds -o name | grep "az-edge.com" | xargs kubectl delete
# MQ
kubectl get crds -o name | grep "mq.iotoperations.azure.com" | xargs kubectl delete

# Symphony
timeout $timeoutSeconds kubectl delete crd instances.symphony.microsoft.com
timeout $timeoutSeconds kubectl delete crd solutions.symphony.microsoft.com
timeout $timeoutSeconds kubectl delete crd targets.symphony.microsoft.com 

# Orchestrator
timeout $timeoutSeconds kubectl delete crd instances.orchestrator.iotoperations.azure.com
timeout $timeoutSeconds kubectl delete crd solutions.orchestrator.iotoperations.azure.com
timeout $timeoutSeconds kubectl delete crd targets.orchestrator.iotoperations.azure.com

# Bluefin
timeout $timeoutSeconds kubectl delete crd datasets.bluefin.az-bluefin.com
timeout $timeoutSeconds kubectl delete crd pipelines.bluefin.az-bluefin.com
timeout $timeoutSeconds kubectl delete crd instances.bluefin.az-bluefin.com

# DataProcessor
timeout $timeoutSeconds kubectl delete crd datasets.dataprocessor.iotoperations.azure.com
timeout $timeoutSeconds kubectl delete crd pipelines.dataprocessor.iotoperations.azure.com
timeout $timeoutSeconds kubectl delete crd instances.dataprocessor.iotoperations.azure.com

echo ""
kubectl get crd -A