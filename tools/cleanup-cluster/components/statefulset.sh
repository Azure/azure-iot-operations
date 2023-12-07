#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm statefulset.sh"

echo ""
kubectl delete statefulset --all

echo ""
kubectl get statefulset -A
