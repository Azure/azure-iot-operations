#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm role.sh"

echo ""
kubectl delete role --all -n alice-springs
kubectl delete role --all -n alice-springs-solution
kubectl delete role --all -n azure-iot-operations
kubectl delete role --all -n azure-iot-operations-solution
kubectl delete role --all -n symphony-k8s-system
kubectl delete role --all -n custom-location-a

kubectl delete role $(kubectl get role -A | grep symphony-cert-manager) -n kube-system
kubectl delete role $(kubectl get role -A | grep aio-cert-manager) -n kube-system

echo ""
kubectl get role -A
