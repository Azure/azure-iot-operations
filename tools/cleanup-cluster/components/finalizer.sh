#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm finalizer.sh"

specFinalizersJsonpath='{.spec.finalizers}'
metadatafinalizersJsonpath='{.metadata.finalizers}'

specFinalizers='{"spec":{"finalizers":null}}'
metadataFinalizers='{"metadata":{"finalizers":null}}'

symphonyInstancesCRD="instances.symphony.microsoft.com"
symphonySolutionsCRD="solutions.symphony.microsoft.com"
symphonyTargetsCRD="targets.symphony.microsoft.com"

bluefinPipelinesCRD="pipelines.bluefin.az-bluefin.com"
bluefinInstancesCRD="instances.bluefin.az-bluefin.com"

# Symphony
echo ""
echo "$symphonyInstancesCRD finalizers:"
kubectl get crd $symphonyInstancesCRD -o jsonpath=$metadatafinalizersJsonpath
echo ""
echo "Patching CRD: $symphonyInstancesCRD with finalizer: $metadataFinalizers..."
kubectl patch crd $symphonyInstancesCRD -p $metadataFinalizers --type merge

echo ""
echo "$symphonySolutionsCRD finalizers:"
kubectl get crd $symphonySolutionsCRD -o jsonpath=$metadatafinalizersJsonpath
echo ""
echo "Patching CRD: $symphonySolutionsCRD with finalizer: $metadataFinalizers..."
kubectl patch crd $symphonySolutionsCRD -p $metadataFinalizers --type merge

echo ""
echo "$symphonyTargetsCRD finalizers:"
kubectl get crd $symphonyTargetsCRD -o jsonpath=$metadatafinalizersJsonpath
echo ""
echo "Patching CRD: $symphonyTargetsCRD with finalizer: $metadataFinalizers..."
kubectl patch crd $symphonyTargetsCRD -p $metadataFinalizers --type merge

# Bluefin
echo ""
echo "$bluefinPipelinesCRD finalizers:"
kubectl get crd $bluefinPipelinesCRD -o jsonpath=$metadatafinalizersJsonpath
echo ""
echo "Patching CRD: $bluefinPipelinesCRD with finalizer: $metadataFinalizers..."
kubectl patch crd $bluefinPipelinesCRD -p $metadataFinalizers --type merge

echo ""
echo "$bluefinInstancesCRD finalizers:"
kubectl get crd $bluefinInstancesCRD -o jsonpath=$metadatafinalizersJsonpath
echo ""
echo "Patching CRD: $bluefinInstancesCRD with finalizer: $metadataFinalizers..."
kubectl patch crd $bluefinInstancesCRD -p $metadataFinalizers --type merge

# Patch namespace does not work, always (no change)
echo ""
echo "$1 namespace finalizers:"
kubectl get namespace $1 -o jsonpath=$specFinalizersJsonpath
echo ""
echo "Patching namespace: $1 with finalizer: $specFinalizers..."
kubectl patch namespace $1 -p $specFinalizers --type merge
