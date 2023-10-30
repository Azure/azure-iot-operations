#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm symphony.sh"

timeoutSeconds=180

# Delete symphony targets
resourceType="microsoft.symphony/targets"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting target resource: $id..."
    timeout $timeoutSeconds az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

# Delete symphony instances
resourceType="microsoft.symphony/instances"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting instance resource: $id..."
    timeout $timeoutSeconds az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

# Delete symphony solutions
resourceType="microsoft.symphony/solutions"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting solution resource: $id..."
    timeout $timeoutSeconds az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

# Delete orchestrator targets
resourceType="microsoft.iotoperationsorchestrator/targets"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting target resource: $id..."
    timeout $timeoutSeconds az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

# Delete orchestrator instances
resourceType="microsoft.iotoperationsorchestrator/instances"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting instance resource: $id..."
    timeout $timeoutSeconds az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

# Delete orchestrator solutions
resourceType="microsoft.iotoperationsorchestrator/solutions"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting solution resource: $id..."
    timeout $timeoutSeconds az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

echo ""
echo "Listing all remaining resources in resource group: $1..."
az resource list -g $1 -o table
