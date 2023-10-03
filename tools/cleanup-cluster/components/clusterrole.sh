#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm clusterrole.sh"

kubectl delete clusterrole $(kubectl get clusterrole -A | grep azedge-)
kubectl delete clusterrole $(kubectl get clusterrole -A | grep bluefin-)
kubectl delete clusterrole $(kubectl get clusterrole -A | grep symphony-)
kubectl delete clusterrole $(kubectl get clusterrole -A | grep alice-springs-)

echo ""
kubectl get clusterrole -A
