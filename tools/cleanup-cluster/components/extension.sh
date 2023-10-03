#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm extension.sh"

echo ""
echo "Deleting Arc extensions..."
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n alice-springs --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n processor --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n data-plane --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n assets --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n e4k --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n adr --yes --force
az k8s-extension delete -g $1 -c $2 -t connectedClusters -n bluefin --yes --force

echo ""
az k8s-extension list -g $1 -c $2 -t connectedClusters -o table
