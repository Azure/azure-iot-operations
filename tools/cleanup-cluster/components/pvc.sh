#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm pvc.sh"

echo ""
kubectl delete pvc --all

echo ""
kubectl get pvc -A
