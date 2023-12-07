# Prerequisites: Azure CLI, kubectl, openssl

$ErrorActionPreference='Stop'

##############################################################################
# The below variables are used in the following commands. Please update them #
# to reflect the details for your Azure subscription and your cluster.       #
##############################################################################
Set-Variable -Name "SUBSCRIPTION" -Value "<SUBSCRIPTION_ID>" -Option Constant
Set-Variable -Name "RESOURCE_GROUP" -Value "<RESOURCE_GROUP>" -Option Constant
Set-Variable -Name "CLUSTER_NAME" -Value "<CLUSTER_NAME>" -Option Constant
Set-Variable -Name "TENANT_ID" -Value "<TENANT_ID>" -Option Constant
Set-Variable -Name "AKV_SP_CLIENTID" -Value "<AKV_SP_CLIENTID>" -Option Constant
Set-Variable -Name "AKV_SP_CLIENTSECRET" -Value "<AKV_SP_CLIENTSECRET>" -Option Constant
Set-Variable -Name "AKV_NAME" -Value "<AKV_NAME>" -Option Constant

Set-Variable -Name "AKV_SECRET_PROVIDER_NAME" -Value "<AKV_SECRET_PROVIDER_NAME>" -Option Constant
Set-Variable -Name "AKV_PROVIDER_POLLING_INTERVAL" -Value "1h" -Option Constant
Set-Variable -Name "DEFAULT_NAMESPACE" -Value "azure-iot-operations" -Option Constant

##############################################################################
# The below commands are used log in to your Azure account and subscription. #
##############################################################################
Write-Host "Logging into azure"
az login --use-device-code
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
Write-Host "Adding the AKV Provider CSI Driver"
az k8s-extension create --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP `
--cluster-type connectedClusters `
--extension-type Microsoft.AzureKeyVaultSecretsProvider `
--name $AKV_SECRET_PROVIDER_NAME `
--configuration-settings secrets-store-csi-driver.enableSecretRotation=true secrets-store-csi-driver.rotationPollInterval=$AKV_PROVIDER_POLLING_INTERVAL secrets-store-csi-driver.syncSecret.enabled=false

##############################################################################
# The below command will create the alice-springs namespace in your cluster. #
# This is required for the SecretProviderClass custom resources as they must #
# reside in the same namespace as the pods that will reference them. If you  #
# already have created the namespaces, comment out the below commands.       #
##############################################################################
Write-Host "Creating the namespaces"
kubectl create namespace $DEFAULT_NAMESPACE

##############################################################################
# The below commands will add a k8s secret for the AKV service principal     #
# that was created and given access to your AKV.                             #
#                                                                            #
#               !!! DO NOT CHANGE THE NAME OF THE SECRET !!!                 #
#                                                                            #
##############################################################################
Write-Host "Adding AKV SP to secrets store in the namespaces"
kubectl create secret generic aio-akv-sp --from-literal clientid="$AKV_SP_CLIENTID" --from-literal clientsecret="$AKV_SP_CLIENTSECRET" --namespace $DEFAULT_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl label secret aio-akv-sp secrets-store.csi.k8s.io/used=true --namespace $DEFAULT_NAMESPACE

##############################################################################
# The below command will create the four required SecretProviderClasses into #
# the cluster, referencing the secrets from AKV.                  #
#                                                                            #
#    !!! DO NOT CHANGE THE NAMES OF ANY OF THE SECRETPROVIDERCLASSES !!!     #
#                                                                            #
##############################################################################
Write-Host "Creating Azure IoT Operations Default SecretProviderClass"
$yaml = @"
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
          objectName: E4KPassword
          objectType: secret
          objectVersion: ""
        - |
          objectName: E4KClientID
          objectType: secret
          objectVersion: ""
    tenantId: $TENANT_ID
"@

$yaml | kubectl apply -f -


Write-Host "Creating Azure IoT Operations OPC-UA SecretProviderClasses"
$yaml = @"
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: aio-opc-ua-broker-client-certificate
  namespace: $DEFAULT_NAMESPACE
spec:
  provider: "azure"
  parameters:
    usePodIdentity: "false"
    keyvaultName: "$AKV_NAME"
    objects: |
      array:
        - |
          objectName: E4KPassword
          objectType: secret
          objectVersion: ""
        - |
          objectName: E4KClientID
          objectType: secret
          objectVersion: ""
    tenantId: $TENANT_ID
"@

$yaml | kubectl apply -f -


$yaml = @"
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: aio-opc-ua-broker-user-authentication
  namespace: $DEFAULT_NAMESPACE
spec:
  provider: "azure"
  parameters:
    usePodIdentity: "false"
    keyvaultName: "$AKV_NAME"
    objects: |
      array:
        - |
          objectName: E4KPassword
          objectType: secret
          objectVersion: ""
        - |
          objectName: E4KClientID
          objectType: secret
          objectVersion: ""
    tenantId: $TENANT_ID
"@

$yaml | kubectl apply -f -

$yaml = @"
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: aio-opc-ua-broker-trust-list
  namespace: $DEFAULT_NAMESPACE
spec:
  provider: "azure"
  parameters:
    usePodIdentity: "false"
    keyvaultName: "$AKV_NAME"
    objects: |
      array:
        - |
          objectName: E4KPassword
          objectType: secret
          objectVersion: ""
        - |
          objectName: E4KClientID
          objectType: secret
          objectVersion: ""
    tenantId: $TENANT_ID
"@

$yaml | kubectl apply -f -

##############################################################################
# The below commands will create the test CA certificate used to encrypt     #
# traffic in the cluster.                                                    #
##############################################################################
Set-Content -Path "ca.conf" -Value @"
[ req ]
distinguished_name = req_distinguished_name
prompt = no
x509_extensions = v3_ca

[ req_distinguished_name ]
CN=Azure IoT Operations Quickstart Root CA - Not for Production

[ v3_ca ]
basicConstraints = critical, CA:TRUE
keyUsage = keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
"@

openssl ecparam -name prime256v1 -genkey -noout -out ca-cert-key.pem
openssl req -new -x509 -key ca-cert-key.pem -days 30 -config ca.conf -out ca-cert.pem
rm ca.conf

kubectl create secret tls aio-ca-key-pair-test-only --cert=./ca-cert.pem --key=./ca-cert-key.pem --namespace $DEFAULT_NAMESPACE
kubectl create cm aio-ca-trust-bundle-test-only --from-file=ca.crt=./ca-cert.pem --namespace $DEFAULT_NAMESPACE
