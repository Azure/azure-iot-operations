echo ""
echo "##############################################################"
echo "I'm instance.sh"

# Clean up finalizers to allow deletion of instances
kubectl -n azure-iot-operations get -o name instances.orchestrator.iotoperations.azure.com | xargs -I {} kubectl -n azure-iot-operations patch {} -p '{"metadata":{"finalizers":[]}}' --type=merge

echo ""
kubectl get instances.orchestrator.iotoperations.azure.com -A