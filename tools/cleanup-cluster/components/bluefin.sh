#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm bluefin.sh"

cloudName="AzureCloud"
resourceManagerEndpointQuery="endpoints.resourceManager"
resourceManagerEndpointUrlPublic="https://management.azure.com/"
resourceManagerEndpointUrlCanary="https://eastus2euap.management.azure.com"

echo ""
echo "Updating your current resource manager endpoint to: $resourceManagerEndpointUrlCanary..."
az cloud update -n $cloudName --endpoint-resource-manager $resourceManagerEndpointUrlCanary
echo "Updated your resource manager endpoint to:"
az cloud show -n $cloudName --query $resourceManagerEndpointQuery

# Delete all Bluefin datasets
resourceType="microsoft.bluefin/instances/datasets"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting dataset resource: $id..."
    az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

# Delete all Bluefin pipelines
resourceType="microsoft.bluefin/instances/pipelines"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting pipeline resource: $id..."
    az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

# Delete all Bluefin instances
resourceType="microsoft.bluefin/instances"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting instance resource: $id..."
    az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

echo ""
az resource list -g $1 -o table

echo ""
echo "Reverting your Canary resource manager endpoint back to: $resourceManagerEndpointUrlPublic..."
az cloud update -n $cloudName --endpoint-resource-manager $resourceManagerEndpointUrlPublic
echo "Reverted your resource manager endpoint back to:"
az cloud show -n $cloudName --query $resourceManagerEndpointQuery
