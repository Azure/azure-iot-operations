#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm clusterrolebinding.sh"

# kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep azedge-)
kubectl delete clusterrolebinding azedge-dmqtt-health-manager
kubectl delete clusterrolebinding azedge-dmqtt-token-review
kubectl delete clusterrolebinding azedge-e4k-operator

# kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep bluefin-)
kubectl delete clusterrolebinding bluefin-nfs-server-provisioner
kubectl delete clusterrolebinding bluefin-operator-manager-admin-rolebinding
kubectl delete clusterrolebinding bluefin-operator-manager-rolebinding
kubectl delete clusterrolebinding bluefin-operator-proxy-rolebinding

# kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep symphony-)
kubectl delete clusterrolebinding symphony-cert-manager-cainjector
kubectl delete clusterrolebinding symphony-cert-manager-controller-approve:cert-manager-io
kubectl delete clusterrolebinding symphony-cert-manager-controller-certificates
kubectl delete clusterrolebinding symphony-cert-manager-controller-certificatesigningrequests
kubectl delete clusterrolebinding symphony-cert-manager-controller-certificatesigningrequests
kubectl delete clusterrolebinding symphony-cert-manager-controller-clusterissuers
kubectl delete clusterrolebinding symphony-cert-manager-controller-ingress-shim
kubectl delete clusterrolebinding symphony-cert-manager-controller-issuers
kubectl delete clusterrolebinding symphony-cert-manager-controller-orders
kubectl delete clusterrolebinding symphony-cert-manager-webhook:subjectaccessreviews
kubectl delete clusterrolebinding symphony-hook-binding
kubectl delete clusterrolebinding symphony-manager-rolebinding
kubectl delete clusterrolebinding symphony-proxy-rolebinding

echo ""
kubectl get clusterrolebinding -A
