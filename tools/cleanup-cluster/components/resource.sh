#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm resource.sh"

timeoutSeconds=90

# Custom Location namespace
echo ""
kubectl delete all --all -n custom-location-a
kubectl get all -n custom-location-a

# Symphony namespace
echo ""
kubectl delete all --all -n $4
kubectl get all -n $4

# Alice Springs namespace
echo ""
# Timeout 'terminating' stage
timeout $timeoutSeconds kubectl delete all --all -n alice-springs
kubectl get all -n alice-springs

# Alice Springs Solution namespace
echo ""
# Timeout 'terminating' stage
timeout $timeoutSeconds kubectl delete all --all -n alice-springs-solution
kubectl get all -n alice-springs-solution

# AIO namespace
echo ""
# Timeout 'terminating' stage
timeout $timeoutSeconds kubectl delete all --all -n azure-iot-operations
kubectl get all -n azure-iot-operations

# AIO Solution namespace
echo ""
# Timeout 'terminating' stage
timeout $timeoutSeconds kubectl delete all --all -n azure-iot-operations-solution
kubectl get all -n azure-iot-operations-solution
