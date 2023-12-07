#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm pv.sh"

timeoutSeconds=120

echo ""
timeout $timeoutSeconds kubectl delete pv --all

echo ""
kubectl get pv -A
