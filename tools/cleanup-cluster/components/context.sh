#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm context.sh"

echo ""
echo "Setting kubectl context: $1"
kubectl config use-context $1

echo ""
echo "You MUST use the correct k8s context, double check from below get-contexts list:"
kubectl config get-contexts

echo ""
echo "Your current k8s context is:"
kubectl config current-context

if [ "$2" != "--yes" ]; then
    echo ""
    echo "Please STOP here if the current k8s context is NOT correct!"

    echo ""
    echo "Continue?"
    echo "Press ENTER to continue or press Ctrl+C to exit..."
    read input
fi
