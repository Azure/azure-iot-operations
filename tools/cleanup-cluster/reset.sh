#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# NOTES:
# This script is used for deleting Project Alice Springs resources
# It assumes you deployed Project Alice Springs by following https://github.com/Azure/project-alice-springs, and you understand the variables you configured in the deployment
# Be very careful updating below variables, they should be the same as what you used in the deployment
# Wrongly updating these values may delete resources you don't want to delete, or delete resources belong to others who share the same subscription
# After deleting these resources, they're permanently gone and cannot be recovered

# The subscription id where your Project Alice Springs resources are created
subscription="<<SUBSCRIPTION_ID>>"

# The resource group where your Project Alice Springs resources are located in above subscription
# You can find this value from Azure portal
resourcegroup="<<RESOURCE_GROUP_NAME>>"

# The k8s cluster name that you connected to Azure Arc and deployed Project Alice Springs resources
# You can find this value from the resource group above
cluster="<<K8S_CLUSTER_NAME>>"

# The cluster context of the k8s cluster above
# You can find a list of available k8s cluster contexts on your current machine by running "kubectl config get-contexts"
# Choose the value from the list carefully, this script will delete all resources under this context
# If the k8s cluster context does not exist, you can run "az aks get-credentials --resource-group RESOURCE_GROUP_NAME --name K8S_CLUSTER_NAME [--admin]" to store the context locally
context="<<K8S_CLUSTER_CONTEXT>>"

namespace="azure-iot-operations" # AIO default namespace
resetOption="Clean up resources inside k8s cluster(default)"
skipLogin=false

check_missing_arg() {
    if [[ "$2" =~ ^-- || -z $2 ]]; then
        echo "Error: Argument for $1 is missing."
        exit 1
    fi
}

# Configure the script arguments    
while [[ $# -gt 0 ]]; do 
    case $1 in
        -a|--all|-s|--symphony)
            resetOption=$1
            shift # Remove --option from processing
            ;;
        --subscription|--resourcegroup|--cluster|--context)
            check_missing_arg $1 $2
            declare $(echo $1 | sed 's/--//')="$2"
            shift 2 # Remove --option and its value from processing
            ;;
        --skip-login)
            skipLogin=true
            shift # Remove --skip-login from processing
            ;;
        --yes)
            autoYes=$1
            shift # Remove --yes from processing
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Subscription ID: $subscription"
echo "Resource Group Name: $resourcegroup"
echo "K8s Cluster Name: $cluster"
echo "K8s Cluster Context: $context"
echo "Reset Option: $resetOption"
echo "Skip Login: $skipLogin"
echo "Auto Yes: $autoYes"

if [ "$skipLogin" = false ] ; then
    echo ""
    sh ./components/login.sh $subscription
    echo ""
fi
sh ./components/context.sh $context $autoYes

# Below scripts are used to delete Alice Springs resources, check each .sh file to understand what it does
# Please contact the author if you have any questions, or submit PR directly for review
echo ""
echo "##############################################################"
echo "I'm reset.sh"

case $resetOption in
    -a|--all)
        echo "Deleting entire resource group, you will have to recreate k8s cluster and Arc enable it again..."
        sh ./components/rg.sh $resourcegroup
        ;;

    -s|--symphony)
        echo "Deleting Alice Springs cloud resources and everything inside k8s cluster..."
        sh ./components/mq.sh $resourcegroup
        if [ $? -eq 1 ]; then
            exit 1
        fi
        sh ./components/symphony.sh $resourcegroup 
        sh ./components/bluefin.sh $resourcegroup
        sh ./components/customlocation.sh $resourcegroup
        sh ./components/extension.sh $resourcegroup $cluster
        ;;

    *)
        echo "Deleting Alice Springs resources inside k8s cluster..."
        ;;
esac

sh ./components/helm.sh $namespace

sh ./components/resource.sh
sh ./components/opcuaserver.sh

sh ./components/validatingwebhookconfiguration.sh
sh ./components/mutatingwebhookconfiguration.sh

sh ./components/instance.sh   
sh ./components/target.sh   

sh ./components/role.sh 
sh ./components/rolebinding.sh
sh ./components/clusterrole.sh
sh ./components/clusterrolebinding.sh

sh ./components/statefulset.sh
sh ./components/force.sh
sh ./components/pvc.sh
sh ./components/pv.sh
sh ./components/sc.sh
sh ./components/customlocationsettings.sh
sh ./components/crd.sh

sh ./components/namespace.sh
if [ $? -eq 1 ]; then
    exit 1
fi

echo ""
echo "Done!"
echo "##############################################################"