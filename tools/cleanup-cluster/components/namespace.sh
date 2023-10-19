#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm namespace.sh"

# Custom location namespace
echo ""
echo "Deleting namespace: $3..."
kubectl delete namespace $3

# Symphony namespace
echo ""
echo "Deleting namespace: $4..."
kubectl delete namespace $4

# Alice Springs namespace
echo ""
echo "Deleting namespace: $2..."
kubectl delete namespace $2

# Alice Springs Solution namespace
echo ""
echo "Deleting namespace: $5..."
kubectl delete namespace $5

echo ""
kubectl get namespace -A