#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm mutatingwebhookconfiguration.sh"

echo ""
kubectl delete mutatingwebhookconfigurations $(kubectl get mutatingwebhookconfigurations -A | grep symphony-)

echo ""
kubectl get mutatingwebhookconfiguration -A
