#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm sc.sh"

echo ""
kubectl delete sc nfs

echo ""
kubectl get sc -A
