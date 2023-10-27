#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm helm.sh"

echo ""
echo "Uninstall all Alice Springs' helm deployments in current k8s cluster..."
echo ""

helm uninstall adr
helm uninstall akri

helm uninstall bluefin
helm uninstall bf-instance

helm uninstall processor
helm uninstall processor-instance

helm uninstall opc-ua-broker
helm uninstall assets

helm uninstall e4in

helm uninstall e4i
helm uninstall e4i-assets
helm uninstall e4i-opcua-connector

helm uninstall e4k
helm uninstall e4k-high-availability-broker
helm uninstall mq

helm uninstall observability
helm uninstall project-alice-springs

echo ""
helm list -A -a