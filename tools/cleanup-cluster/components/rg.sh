#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm rg.sh"

timeoutSeconds=300

echo ""
echo "Listing all resources in resource group: $1..."
az resource list -g $1 -o table

echo ""
echo "Deleting entire resource group: $1..."
echo "Continue?"
echo "Press ENTER to continue or press Ctrl+C to exit..."
read input

cloudName="AzureCloud"
resourceManagerEndpointQuery="endpoints.resourceManager"
resourceManagerEndpointUrlPublic="https://management.azure.com/"
resourceManagerEndpointUrlCanary="https://eastus2euap.management.azure.com"

echo ""
echo "Updating your current resource manager endpoint to: $resourceManagerEndpointUrlCanary..."
az cloud update -n $cloudName --endpoint-resource-manager $resourceManagerEndpointUrlCanary
echo "Updated your resource manager endpoint to:"
az cloud show -n $cloudName --query $resourceManagerEndpointQuery

echo ""
echo "Deleting resource group: $1..."
timeout $timeoutSeconds az group delete --name $1 --yes

echo ""
echo "Reverting your Canary resource manager endpoint back to: $resourceManagerEndpointUrlPublic..."
az cloud update -n $cloudName --endpoint-resource-manager $resourceManagerEndpointUrlPublic
echo "Reverted your resource manager endpoint back to:"
az cloud show -n $cloudName --query $resourceManagerEndpointQuery
