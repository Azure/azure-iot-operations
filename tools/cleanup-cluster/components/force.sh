#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm force.sh"

# Alice Springs namespace
echo ""
echo "Listing bad resources in namespace: alice-springs..."
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n alice-springs

echo ""
echo "Force deleting bad resources in namespace: alice-springs..."
kubectl delete pod bluefin-runner-worker-0 --grace-period=0 --force --namespace alice-springs
kubectl delete pod aio-dp-runner-worker-0 --grace-period=0 --force --namespace alice-springs

# Alice Springs Solution namespace
echo ""
echo "Listing bad resources in namespace: alice-springs-solution..."
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n alice-springs-solution

echo ""
echo "Force deleting bad resources in namespace: alice-springs-solution..."
kubectl delete pod bluefin-runner-worker-0 --grace-period=0 --force --namespace alice-springs-solution
kubectl delete pod aio-dp-runner-worker-0 --grace-period=0 --force --namespace alice-springs-solution

# AIO namespace
echo ""
echo "Listing bad resources in namespace: azure-iot-operations..."
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n azure-iot-operations

echo ""
echo "Force deleting bad resources in namespace: azure-iot-operations..."
kubectl delete pod bluefin-runner-worker-0 --grace-period=0 --force --namespace azure-iot-operations
kubectl delete pod aio-dp-runner-worker-0 --grace-period=0 --force --namespace azure-iot-operations

# AIO Solution namespace
echo ""
echo "Listing bad resources in namespace: azure-iot-operations-solution..."
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n alice-springs-solution

echo ""
echo "Force deleting bad resources in namespace: azure-iot-operations-solution..."
kubectl delete pod bluefin-runner-worker-0 --grace-period=0 --force --namespace azure-iot-operations-solution
kubectl delete pod aio-dp-runner-worker-0 --grace-period=0 --force --namespace azure-iot-operations-solution
