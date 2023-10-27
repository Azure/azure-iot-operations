#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm statefulset.sh"

echo ""
kubectl delete statefulset --all

echo ""
kubectl get statefulset -A
