#!/bin/bash

# NOTES:
# This script is used for deleting Project Alice Springs resources
# It assumes you deployed Project Alice Springs by following https://github.com/Azure/project-alice-springs, and you understand the variables you configured in the deployment
# Be very careful updating below variables, they should be the same as what you used in the deployment
# Wrongly updating these values may delete resources you don't want to delete, or delete resources belong to others who share the same subscription
# After deleting these resources, they're permanently gone and cannot be recovered

# The subscription id where your Project Alice Springs resources are created
subscriptionId="<<SUBSCRIPTION_ID>>"

# The resource group where your Project Alice Springs resources are located in above subscription
# You can find this value from Azure portal
resourceGroupName="<<RESOURCE_GROUP_NAME>>"

# The k8s cluster name that you connected to Azure Arc and deployed Project Alice Springs resources
# You can find this value from the resource group above
k8sClusterName="<<K8S_CLUSTER_NAME>>"

# The cluster context of the k8s cluster above
# You can find a list of available k8s cluster contexts on your current machine by running "kubectl config get-contexts"
# Choose the value from the list carefully, this script will delete all resources under this context
# If the k8s cluster context does not exist, you can run "az aks get-credentials --resource-group RESOURCE_GROUP_NAME --name K8S_CLUSTER_NAME [--admin]" to store the context locally
k8sClusterContext="<<K8S_CLUSTER_CONTEXT>>"

# Below scripts are used to delete Alice Springs resources, check each .sh file to understand what it does
# Please contact the author if you have any questions, or submit PR directly for review
echo ""
echo "##############################################################"
echo "I'm reset.sh"

resetOption=$1

echo ""
echo "Rest option: $resetOption" 

echo ""
sh ./components/login.sh $subscriptionId
echo ""

sh ./components/context.sh $k8sClusterContext

case $resetOption in
    -a|--all)
        echo "Deleting entire resource group, you will have to recreate k8s cluster and Arc enable it again..."
        sh ./components/rg.sh $resourceGroupName
        ;;

    -s|--symphony)
        echo "Deleting Alice Springs cloud resources and everything inside k8s cluster..."
        sh ./components/symphony.sh $resourceGroupName 
        sh ./components/customlocation.sh $resourceGroupName
        sh ./components/bluefin.sh $resourceGroupName
        sh ./components/extension.sh $resourceGroupName $k8sClusterName
        ;;

    *)
        echo "Deleting Alice Springs resources inside k8s cluster..."
        ;;
esac

sh ./components/helm.sh

sh ./components/crd.sh

sh ./components/resource.sh
sh ./components/force.sh
sh ./components/namespace.sh

sh ./components/role.sh 
sh ./components/rolebinding.sh

sh ./components/clusterrole.sh
sh ./components/clusterrolebinding.sh

sh ./components/validatingwebhookconfiguration.sh
sh ./components/mutatingwebhookconfiguration.sh

sh ./components/statefulset.sh
sh ./components/pvc.sh
sh ./components/pv.sh
sh ./components/sc.sh

echo ""
echo "Done!"
echo "##############################################################"