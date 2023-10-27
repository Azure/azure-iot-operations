#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm force.sh"

# Alice Springs namespace
echo ""
echo "Listing bad resources in namespace: $1..."
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n $1

echo ""
echo "Force deleting bad resources in namespace: $1..."
kubectl delete pod bluefin-runner-worker-0 --grace-period=0 --force --namespace $1
kubectl delete pod aio-dp-runner-worker-0 --grace-period=0 --force --namespace $1

# Alice Springs Solution namespace
echo ""
echo "Listing bad resources in namespace: $2..."
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n $2

echo ""
echo "Force deleting bad resources in namespace: $2..."
kubectl delete pod bluefin-runner-worker-0 --grace-period=0 --force --namespace $2
kubectl delete pod aio-dp-runner-worker-0 --grace-period=0 --force --namespace $2
