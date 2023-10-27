#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm pvc.sh"

echo ""
kubectl delete pvc --all

echo ""
kubectl get pvc -A
