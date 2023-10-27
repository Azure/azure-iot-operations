#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm clusterrolebinding.sh"

# kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep aio-mq-)
kubectl delete clusterrolebinding azedge-dmqtt-health-manager
kubectl delete clusterrolebinding azedge-dmqtt-token-review
kubectl delete clusterrolebinding azedge-e4k-operator
kubectl delete clusterrolebinding aio-mq-dmqtt-health-manager
kubectl delete clusterrolebinding aio-mq-dmqtt-token-review
kubectl delete clusterrolebinding aio-mq-operator

# kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep bluefin-)
kubectl delete clusterrolebinding bluefin-nfs-server-provisioner
kubectl delete clusterrolebinding bluefin-operator-manager-admin-rolebinding
kubectl delete clusterrolebinding bluefin-operator-manager-rolebinding
kubectl delete clusterrolebinding bluefin-operator-proxy-rolebinding

# kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep aio-dp-)
kubectl delete clusterrolebinding aio-dp-nfs-server-provisioner
kubectl delete clusterrolebinding aio-dp-operator-manager-admin-rolebinding
kubectl delete clusterrolebinding aio-dp-operator-manager-rolebinding
kubectl delete clusterrolebinding aio-dp-operator-proxy-rolebinding
kubectl delete clusterrolebinding aio-dp-reader-worker-rolebinding
kubectl delete clusterrolebinding aio-dp-refdata-store-rolebinding
kubectl delete clusterrolebinding aio-dp-runner-worker-rolebinding

# kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep symphony-)
kubectl delete clusterrolebinding symphony-cert-manager-cainjector
kubectl delete clusterrolebinding symphony-cert-manager-controller-approve:cert-manager-io
kubectl delete clusterrolebinding symphony-cert-manager-controller-certificates
kubectl delete clusterrolebinding symphony-cert-manager-controller-certificatesigningrequests
kubectl delete clusterrolebinding symphony-cert-manager-controller-challenges
kubectl delete clusterrolebinding symphony-cert-manager-controller-clusterissuers
kubectl delete clusterrolebinding symphony-cert-manager-controller-ingress-shim
kubectl delete clusterrolebinding symphony-cert-manager-controller-issuers
kubectl delete clusterrolebinding symphony-cert-manager-controller-orders
kubectl delete clusterrolebinding symphony-cert-manager-webhook:subjectaccessreviews
kubectl delete clusterrolebinding symphony-hook-binding
kubectl delete clusterrolebinding symphony-manager-rolebinding
kubectl delete clusterrolebinding symphony-proxy-rolebinding

# kubectl delete clusterrolebinding $(kubectl get clusterrolebinding -A | grep aio-)
kubectl delete clusterrolebinding aio-cert-manager-cainjector
kubectl delete clusterrolebinding aio-cert-manager-controller-approve:cert-manager-io
kubectl delete clusterrolebinding aio-cert-manager-controller-certificates
kubectl delete clusterrolebinding aio-cert-manager-controller-certificatesigningrequests
kubectl delete clusterrolebinding aio-cert-manager-controller-challenges
kubectl delete clusterrolebinding aio-cert-manager-controller-clusterissuers
kubectl delete clusterrolebinding aio-cert-manager-controller-ingress-shim
kubectl delete clusterrolebinding aio-cert-manager-controller-issuers
kubectl delete clusterrolebinding aio-cert-manager-controller-orders
kubectl delete clusterrolebinding aio-cert-manager-webhook:subjectaccessreviews
kubectl delete clusterrolebinding aio-hook-binding
kubectl delete clusterrolebinding aio-manager-rolebinding
kubectl delete clusterrolebinding aio-proxy-rolebinding

echo ""
kubectl get clusterrolebinding -A
