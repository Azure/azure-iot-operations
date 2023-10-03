#!/bin/sh

# exit when any command fails
set -e

##############################################################################
# The below variables are used in the following commands. Please update them #
# to reflect the details for your Azure subscription and your cluster.       #
##############################################################################
SUBSCRIPTION=<your subscription ID>
RESOURCE_GROUP=<your resource group>
CLUSTER_NAME=<your connected cluster name>
TENANT_ID=<your tenant ID>
AKV_SECRET_PROVIDER_NAME=akvsecretsprovider
AKV_SP_CLIENTID=<your AKV service principal client ID>
AKV_SP_CLIENTSECRET=<your AKV service principal client secert>
AKV_NAME=<you AKV name>
AKV_PROVIDER_POLLING_INTERVAL=1h
DEFAULT_NAMESPACE=alice-springs
SOLUTION_NAMESPACE=alice-springs-solution

##############################################################################
# The below commands are used log in to your Azure account and subscription. #
##############################################################################
echo "Logging into azure"
az login
az account set --subscription $SUBSCRIPTION

##############################################################################
# The below command will install the Azure Key Vault Provider CSI Driver Arc #
# Extension into your cluster. If you already have installed the CSI Driver  #
# Arc Extension into your cluster, comment out the below command.            #
#                                                                            #
# Please update the secrets-store-csi-driver.rotationPollInterval            #
# configuration-setting to set the polling interval that you require for     #
# secrets to be updated on the cluster.                                      #
##############################################################################
echo "Adding the AKV Provider CSI Driver"
az k8s-extension create --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP \
--cluster-type connectedClusters \
--extension-type Microsoft.AzureKeyVaultSecretsProvider \
--name $AKV_SECRET_PROVIDER_NAME \
--configuration-settings secrets-store-csi-driver.enableSecretRotation=true secrets-store-csi-driver.rotationPollInterval=$AKV_PROVIDER_POLLING_INTERVAL secrets-store-csi-driver.syncSecret.enabled=false

##############################################################################
# The below command will create the alice-springs namespace in your cluster. #
# This is required for the SecretProviderClass custom resources as they must #
# reside in the same namespace as the pods that will reference them. If you  #
# already have created the namespaces, comment out the below commands.       #
##############################################################################
echo "Creating the namespaces"
kubectl create namespace $DEFAULT_NAMESPACE
kubectl create namespace $SOLUTION_NAMESPACE

##############################################################################
# The below commands will add a k8s secret for the AKV service principal     #
# that was created and given access to your AKV.                             #
#                                                                            #
#               !!! DO NOT CHANGE THE NAME OF THE SECRET !!!                 #
#                                                                            #
##############################################################################
echo "Adding AKV SP to secrets store in the namespaces"
kubectl create secret generic aio-akv-sp --from-literal clientid="$AKV_SP_CLIENTID" --from-literal clientsecret="$AKV_SP_CLIENTSECRET" --namespace $DEFAULT_NAMESPACE
kubectl label secret aio-akv-sp secrets-store.csi.k8s.io/used=true --namespace $DEFAULT_NAMESPACE
kubectl create secret generic aio-akv-sp --from-literal clientid="$AKV_SP_CLIENTID" --from-literal clientsecret="$AKV_SP_CLIENTSECRET" --namespace $SOLUTION_NAMESPACE
kubectl label secret aio-akv-sp secrets-store.csi.k8s.io/used=true --namespace $SOLUTION_NAMESPACE

##############################################################################
# The below command will create the four required SecretProvdierClasses into #
# the cluster.                                                               #
#                                                                            #
#    !!! DO NOT CHANGE THE NAMES OF ANY OF THE SECRETPROVIDERCLASSES !!!     #
#                                                                            #
# Update the list of secrets under the spec.parameters.objects.array to      #
# contain the explicit list of secrets that you require.                     #
##############################################################################
echo "Creating Azure IoT Operations Default SecretProviderClass"
kubectl apply -f - <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: aio-default-spc
  namespace: $DEFAULT_NAMESPACE
spec:
  provider: "azure"
  parameters:
    usePodIdentity: "false"
    keyvaultName: "$AKV_NAME"
    objects: |
      array:
        - |
          objectName: Secret0
          objectType: secret
          objectVersion: ""
        - |
          objectName: Secret1
          objectType: secret
          objectVersion: ""
    tenantId: $TENANT_ID
EOF

echo "Creating Azure IoT Operations OPC-UA SecretProviderClasses"
kubectl apply -f - <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: aio-opc-ua-broker-client-certificate
  namespace: $SOLUTION_NAMESPACE
spec:
  provider: "azure"
  parameters:
    usePodIdentity: "false"
    keyvaultName: "$AKV_NAME"
    objects: |
      array:
        - |
          objectName: Secret0
          objectType: secret
          objectVersion: ""
        - |
          objectName: Secret1
          objectType: secret
          objectVersion: ""
    tenantId: $TENANT_ID
EOF

kubectl apply -f - <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: aio-opc-ua-broker-user-authentication
  namespace: $SOLUTION_NAMESPACE
spec:
  provider: "azure"
  parameters:
    usePodIdentity: "false"
    keyvaultName: "$AKV_NAME"
    objects: |
      array:
        - |
          objectName: Secret0
          objectType: secret
          objectVersion: ""
        - |
          objectName: Secret1
          objectType: secret
          objectVersion: ""
    tenantId: $TENANT_ID
EOF

kubectl apply -f - <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: aio-opc-ua-broker-trust-list
  namespace: $SOLUTION_NAMESPACE
spec:
  provider: "azure"
  parameters:
    usePodIdentity: "false"
    keyvaultName: "$AKV_NAME"
    objects: |
      array:
        - |
          objectName: Secret0
          objectType: secret
          objectVersion: ""
        - |
          objectName: Secret1
          objectType: secret
          objectVersion: ""
    tenantId: $TENANT_ID
EOF