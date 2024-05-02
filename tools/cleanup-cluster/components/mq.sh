#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo ""
echo "##############################################################"
echo "I'm mq.sh"

timeoutSeconds=60
resourceGroup=$1
maxRetries=3
attempt=0


delete_resource() {
    resourceType=$1
    resourceGroup=$2
    resources="$(az resource list -g $resourceGroup --resource-type $resourceType -o tsv --query '[].id')"
    for id in $resources; do
        echo ""
        echo "Deleting resource: $id..."
        timeout $timeoutSeconds az resource delete -g $resourceGroup --resource-type $resourceType --ids $id --verbose
    done
}

delete_mq_all() {
    resourceGroup=$1
    delete_resource "microsoft.iotoperationsmq/mq/broker/listener" $resourceGroup
    delete_resource "microsoft.iotoperationsmq/mq/broker/authentication" $resourceGroup
    delete_resource "microsoft.iotoperationsmq/mq/broker" $resourceGroup
    delete_resource "microsoft.iotoperationsmq/mq/diagnosticService" $resourceGroup
    delete_resource "microsoft.iotoperationsmq/mq" $resourceGroup
}

check_mq_exists() {
    resourceGroup=$1
    resources="$(az resource list -g $resourceGroup --resource-type "microsoft.iotoperationsmq/mq" -o tsv --query '[].id')"
    if [ -z "$resources" ]; then
        echo "No MQ resources found in resource group $resourceGroup."
        return 1
    fi
    return 0
}

while check_mq_exists $resourceGroup && [ "$attempt" -le "$maxRetries" ]; do
    if [ "$attempt" -eq "$maxRetries" ]; then
        echo "Max retries reached. MQ resources still exist. Exiting..."
        exit 1
    fi
    echo "MQ resources exist in resource group $resourceGroup. Deleting all MQ resources..."
    delete_mq_all $resourceGroup
    attempt=$((attempt+1))
    echo "Waiting for a few seconds before checking again..."
    sleep 10
done

echo "All MQ resources have been successfully deleted from $resourceGroup."