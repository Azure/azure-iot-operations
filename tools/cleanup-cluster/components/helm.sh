#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm helm.sh"

echo ""
echo "Uninstall all AIO helm deployments in current k8s cluster..."
echo ""

# Check if the first argument is provided
if [ -z "$1" ]; then
    namespace="default"  # Default value if no argument is provided
else
    namespace="$1"
fi


helm list -n $namespace -o json | jq -r '.[] | .name' | while read -r helm_release; do
    echo "helm uninstall $helm_release in namespace $namespace..."
    helm uninstall $helm_release -n $namespace --wait --timeout 1m0s
done

echo ""
helm list -A -a
