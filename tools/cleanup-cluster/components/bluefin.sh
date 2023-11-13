#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm bluefin.sh"

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

# Delete all DataProcessor datasets
resourceType="microsoft.iotoperationsdataprocessor/instances/datasets"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting dataset resource: $id..."
    az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

# Delete all DataProcessor pipelines
resourceType="microsoft.iotoperationsdataprocessor/instances/pipelines"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting pipeline resource: $id..."
    az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

# Delete all DataProcessor instances
resourceType="microsoft.iotoperationsdataprocessor/instances"
resources="$(az resource list -g $1 --resource-type $resourceType -o tsv --query '[].id')"
for id in $resources; do
    echo ""
    echo "Deleting instance resource: $id..."
    az resource delete -g $1 --resource-type $resourceType --ids $id --verbose
done

echo ""
az resource list -g $1 -o table
