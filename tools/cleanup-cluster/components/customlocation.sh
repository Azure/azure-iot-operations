#!/bin/bash

echo ""
echo "##############################################################"
echo "I'm customlocation.sh"

apiVersion="2021-08-31-preview"

# Delete all resource sync rules
resourceType="microsoft.extendedlocation/customlocations/resourcesyncrules"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting resource sync rule resource: $id..."
    az resource delete -g $1 --resource-type $resourceType --ids $id --verbose --api-version $apiVersion
done

# Delete all custom locations
resourceType="microsoft.extendedlocation/customlocations"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting custom location resource: $id..."
    az resource delete -g $1 --resource-type $resourceType --ids $id --verbose --api-version $apiVersion
done

echo ""
az resource list -g $1 -o table
