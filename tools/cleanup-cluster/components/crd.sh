#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm crd.sh"

echo ""
echo "Deleting all Alice Springs' CRDs in current k8s cluster..."
echo ""

timeoutSeconds=40

# AKRI
kubectl delete crd instances.akri.sh
kubectl delete crd configurations.akri.sh

# ADR
kubectl delete crd assetendpointprofiles.deviceregistry.microsoft.com

# E4I
kubectl delete crd applications.e4i.microsoft.com 
kubectl delete crd assets.e4i.microsoft.com
kubectl delete crd assettypes.e4i.microsoft.com
kubectl delete crd modules.e4i.microsoft.com
kubectl delete crd moduletypes.e4i.microsoft.com

# E4K
kubectl delete crd brokerauthentications.az-edge.com
kubectl delete crd brokerauthorization.az-edge.com
kubectl delete crd brokerdiagnostics.az-edge.com
kubectl delete crd diagnosticservices.az-edge.com
kubectl delete crd brokerlisteners.az-edge.com
kubectl delete crd brokers.az-edge.com
kubectl delete crd mqttbridgeconnectors.az-edge.com
kubectl delete crd mqttbridgetopicmaps.az-edge.com
kubectl delete crd e4inz.az-edge.com
kubectl delete crd e4ks.az-edge.com

# Symphony
timeout $timeoutSeconds kubectl delete crd instances.symphony.microsoft.com
timeout $timeoutSeconds kubectl delete crd solutions.symphony.microsoft.com
timeout $timeoutSeconds kubectl delete crd targets.symphony.microsoft.com 

# Bluefine
timeout $timeoutSeconds kubectl delete crd datasets.bluefin.az-bluefin.com
timeout $timeoutSeconds kubectl delete crd pipelines.bluefin.az-bluefin.com
timeout $timeoutSeconds kubectl delete crd instances.bluefin.az-bluefin.com

echo ""
kubectl get crd -A