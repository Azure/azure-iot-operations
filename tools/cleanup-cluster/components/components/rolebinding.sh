#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm rolebinding.sh"

echo ""
echo "Deleting rolebinding in namespace: $1..."
kubectl delete rolebinding --all -n $1

echo ""
echo "Deleting rolebinding in namespace: $2..."
kubectl delete rolebinding --all -n $2

echo ""
echo "Deleting rolebinding in namespace: $3..."
kubectl delete rolebinding --all -n $3

echo ""
echo "Deleting rolebinding in namespace: $4..."
kubectl delete rolebinding --all -n $4

# kubectl delete rolebinding $(kubectl get rolebinding -A | grep symphony-cert-manager) -n kube-system
kubectl delete rolebinding symphony-cert-manager-cainjector:leaderelection -n kube-system
kubectl delete rolebinding symphony-cert-manager:leaderelection -n kube-system

# kubectl delete rolebinding $(kubectl get rolebinding -A | grep aio-cert-manager) -n kube-system
kubectl delete rolebinding aio-cert-manager-cainjector:leaderelection -n kube-system
kubectl delete rolebinding aio-cert-manager:leaderelection -n kube-system

echo ""
kubectl get rolebinding -A
