#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm pv.sh"

echo ""
kubectl delete pv --all

echo ""
kubectl get pv -A
