#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm target.sh"

metadatafinalizersJsonpath='{.metadata.finalizers}'
metadataFinalizers='{"metadata":{"finalizers":null}}'

echo ""
echo "$2 finalizers:"
kubectl get target $2 -n $1 -o jsonpath=$metadatafinalizersJsonpath
echo ""
echo "Patching: $2 with finalizer: $metadataFinalizers..."
kubectl patch target $2 -n $1 -p $metadataFinalizers --type merge

echo ""
kubectl get target -A
