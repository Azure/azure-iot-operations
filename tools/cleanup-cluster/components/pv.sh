#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm pv.sh"

timeoutSeconds=120

echo ""
timeout $timeoutSeconds kubectl delete pv --all

echo ""
kubectl get pv -A
