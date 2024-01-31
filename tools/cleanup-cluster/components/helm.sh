#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm helm.sh"

echo ""
echo "Uninstall all Alice Springs' helm deployments in current k8s cluster..."
echo ""

# Check if the first argument is provided
if [ -z "$1" ]; then
    namespace="default"  # Default value if no argument is provided
else
    namespace="$1"
fi

helm uninstall adr -n $namespace
helm uninstall akri -n $namespace

helm uninstall bluefin -n $namespace
helm uninstall bf-instance -n $namespace

helm uninstall processor -n $namespace
helm uninstall processor-instance -n $namespace

helm uninstall opc-ua-broker -n $namespace
helm uninstall assets -n $namespace

helm uninstall e4in -n $namespace

helm uninstall e4i -n $namespace
helm uninstall e4i-assets -n $namespace
helm uninstall e4i-opcua-connector -n $namespace

helm uninstall e4k -n $namespace
helm uninstall e4k-high-availability-broker -n $namespace
helm uninstall mq -n $namespace

helm uninstall observability -n $namespace
helm uninstall project-alice-springs -n $namespace

helm uninstall orca-opc-plc-operator -n $namespace
helm uninstall telegraf -n $namespace

echo ""
helm list -A -a