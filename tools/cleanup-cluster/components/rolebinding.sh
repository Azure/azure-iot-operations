#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm rolebinding.sh"

echo ""
kubectl delete rolebinding --all -n alice-springs
kubectl delete rolebinding --all -n alice-springs-solution
kubectl delete rolebinding --all -n azure-iot-operations
kubectl delete rolebinding --all -n azure-iot-operations-solution
kubectl delete rolebinding --all -n symphony-k8s-system
kubectl delete rolebinding --all -n custom-location-a

kubectl delete rolebinding symphony-cert-manager-cainjector:leaderelection -n kube-system
kubectl delete rolebinding symphony-cert-manager:leaderelection -n kube-system
kubectl delete rolebinding aio-cert-manager-cainjector:leaderelection -n kube-system
kubectl delete rolebinding aio-cert-manager:leaderelection -n kube-system

echo ""
kubectl get rolebinding -A
