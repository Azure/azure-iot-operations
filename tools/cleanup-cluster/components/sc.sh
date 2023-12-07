#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm sc.sh"

echo ""
kubectl delete sc nfs

echo ""
kubectl get sc -A
