#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm role.sh"

echo ""
echo "Deleting roles in namespace: $1..."
kubectl delete role --all -n $1

echo ""
echo "Deleting roles in namespace: $2..."
kubectl delete role --all -n $2

echo ""
echo "Deleting roles in namespace: $3..."
kubectl delete role --all -n $3

echo ""
echo "Deleting roles in namespace: $4..."
kubectl delete role --all -n $4

kubectl delete role $(kubectl get role -A | grep symphony-cert-manager) -n kube-system

echo ""
kubectl get role -A
