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
kubectl get crds -o name | grep ".akri.sh" | xargs -I {} timeout $timeoutSeconds kubectl delete {} 

# ADR
kubectl get crds -o name | grep ".deviceregistry.microsoft.com" | xargs -I {} timeout $timeoutSeconds kubectl delete {} 

# E4I
kubectl get crds -o name | grep ".e4i.microsoft.com" | xargs -I {} timeout $timeoutSeconds kubectl delete {} 

# E4K
kubectl get crds -o name | grep ".az-edge.com" | xargs kubectl delete

# Symphony
kubectl get crds -o name | grep ".symphony.microsoft.com" | xargs -I {} timeout $timeoutSeconds kubectl delete {} 

# Bluefin
kubectl get crds -o name | grep ".bluefin.az-bluefin.com" | xargs -I {} timeout $timeoutSeconds kubectl delete {} 

# All IoT Operations CRDs
# Known CRDs to be deleted: dataprocessor, mqs, ochestrator, mq, assettypes.opcuabroker, lnmz.layerednetworkmgmt
kubectl get crds -o name | grep ".iotoperations.azure.com" | xargs -I {} timeout $timeoutSeconds kubectl delete {} 

# All Cert Mangers
kubectl get crds -o name | grep ".cert-manager.io" | xargs -I {} timeout $timeoutSeconds kubectl delete {} 

# All Old IoT Operations CRDs
kubectl get crds -o name | grep ".aio.com" | xargs -I {} timeout $timeoutSeconds kubectl delete {}

echo ""
kubectl get crd -A