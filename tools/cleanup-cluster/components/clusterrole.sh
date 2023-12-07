#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm clusterrole.sh"

# clusterroles under old prefixes
kubectl delete clusterrole $(kubectl get clusterrole -A | grep azedge-)
kubectl delete clusterrole $(kubectl get clusterrole -A | grep bluefin-)
kubectl delete clusterrole $(kubectl get clusterrole -A | grep symphony-)
kubectl delete clusterrole $(kubectl get clusterrole -A | grep alice-springs-)
kubectl delete clusterrole $(kubectl get clusterrole -A | grep azure-iot-)

# All AIO clusterroles
# Known clusterroles under this prefix: aio-akri, aio-cert-manager, aio-dp, aio-lnm, aio-mq, aio-orc, aio-opc
kubectl delete clusterrole $(kubectl get clusterrole -A | grep aio-)

echo ""
kubectl get clusterrole -A
