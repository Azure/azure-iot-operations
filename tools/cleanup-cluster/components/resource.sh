#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm resource.sh"

timeoutSeconds=90

# Custom location namespace
echo ""
echo "Deleting all resources in namespace: $3..."
kubectl delete all --all -n $3
echo ""
kubectl get all -n $3

# Symphony namespace
echo ""
echo "Deleting all resources in namespace: $4..."
kubectl delete all --all -n $4
echo ""
kubectl get all -n $4

# Alice Springs namespace
echo ""
echo "Deleting all resources in namespace: $2..."
# Timeout 'terminating' stage
timeout $timeoutSeconds kubectl delete all --all -n $2
echo ""
kubectl get all -n $2

# Alice Springs Solution namespace
echo ""
echo "Deleting all resources in namespace: $5..."
# Timeout 'terminating' stage
timeout $timeoutSeconds kubectl delete all --all -n $5
echo ""
kubectl get all -n $5
