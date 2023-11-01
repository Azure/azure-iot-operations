# azure-iot-operations

## Overview

This repo contains the definition of Azure IoT Operations (AIO) and allows for
AIO to be deployed to an Arc-enabled K8s cluster.

Please follow the Azure IoT Operations [Quickstart](https://alicesprings.ms/docs/quickstart/)

## Forking the Repo

If you want to fork this repo, there are some additional steps you will need to take to set up the fork.

1. Set the `AZURE_CREDENTIALS` repository secret.

    1. Create a Service Principal resource for the repository to use when performing GitHub actions.
        ```bash
        # If you haven't upgraded your Azure CLI lately, run the following.
        az upgrade

        # Create a Service Principal to perform operations on the provided subscription.
        az ad sp create-for-rbac --name $SP_NAME --role owner --scopes /subscriptions/$SUBSCRIPTION_ID --json-auth
        ```

    2. Copy the JSON output from the Service Principal creation command and paste into a repository secret named `AZURE_CREDENTIALS`
        in your fork. Repository secrets can be found under **Settings** > **Secrets and 
       variables** > **Actions**. To learn more, see [creating secrets for a repository](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository).

2. To be able to use secrets in AIO, follow the [AIO Out-of-Band Pre-Install Steps](https://microsoft.sharepoint.com/:w:/t/Bluefin/EWp9JzHXpkhIlcCpMv19hWQB3MWpuqLM03L1G4yPNmbm2Q?e=lunDFS) to create an AKV and a Service Principal with access to AKV.

3. Create and setup K8s Arc-enabled cluster.

    1. If you don't have an existing K8s cluster, try [minikube](https://minikube.sigs.k8s.io/docs/).

    2. Arc-enable your K8s cluster using the [az connectedk8s connect](https://learn.microsoft.com/cli/azure/connectedk8s#az-connectedk8s-connect) command.

        ```bash
        az connectedk8s connect -n $CLUSTER_NAME -l $LOCATION -g $RESOURCE_GROUP --subscription $SUBSCRIPTION_ID
        ```

    3. Use the [az connectedk8s enable-features](https://learn.microsoft.com/cli/azure/connectedk8s?view=azure-cli-latest#az-connectedk8s-enable-features) command to enable custom location support on your cluster.

        ```bash
        az connectedk8s enable-features -n $CLUSTER_NAME -g $RESOURCE_GROUP --custom-locations-oid <objectId/id> --features cluster-connect custom-locations
        ```

    3. Run cluster setup script from `tools/setup-cluster/setup-cluster.sh`.

        1. In setup-cluster.sh, update the variables at the top of the script to have the values for your Azure Subscription, Resources, and Cluster.

4. Deploy Azure IoT Operations.

    1. Create parameter file where environment configuration is specified for your AIO deployment. For an example, see `environments/example.parameters.json`.
    
        | **Parameter** | **Requirement** | **Type** | **Description** |
        | ------------- |--|------------|-------------- |
        | clusterName   | ***[Required]*** | `string` | The Arc-enabled cluster resource in Azure.  |
        | clusterLocation | *[Optional]* | `string` |If the cluster resource's location is different than its resource group's location, the cluster location will need to be specified. Otherwise, this parameter will default to the location of the resource group.  |
        | location      | *[Optional]*  | `string` | If the resource group's location is not a supported AIO region, this parameter can be used to override the location of the AIO resources. |
        | dataProcessorSecrets | *[Optional]*<sup>1</sup>| `object` | Add the name of the SecretProviderClass and k8s AKV SP secret that were created from the `setup-cluster.sh`. This should be something like `aio-default-spc` and `aio-akv-sp`, respectively. <br><br>Example:<br> <pre>{<br>  "secretProviderClassName": "aio-default-spc",<br>  "servicePrincipalSecretRef": "aio-akv-sp"<br>}</pre>|
        | mqSecrets | *[Optional]*<sup>1</sup>| `object` | Add the name of the SecretProviderClass and k8s AKV SP secret that were created from the `setup-cluster.sh`. This should be something like `aio-default-spc` and `aio-akv-sp`, respectively. <br><br>Example:<br> <pre>{<br>  "secretProviderClassName": "aio-default-spc",<br>  "servicePrincipalSecretRef": "aio-akv-sp"<br>}</pre>|
        | opcUaBrokerSecrets | *[Optional]*<sup>1</sup>| `object` | Add the name of the k8s AKV SP secret that was created from the `setup-cluster.sh`. This should be something like `aio-akv-sp` and kind should be `csi`. <br><br>Example:<br> <pre>{<br>  "kind": "csi",<br> "csiServicePrincipalSecretRef": "aio-akv-sp"<br>}</pre>|
        
        > <sup>1</sup> This param is only necessary if you are using different values than the defaults specified in `setup-cluster.sh`.

    2. On the forked repo, select **Actions** and select **I understand my workflows, go ahead and enable them.**

    3. Run the **GitOps Deployment of Azure IoT Operations** GitHub Action. You'll need to provide both the `subscription` and `resource group` where your Arc-enabled cluster resource is and the path to the `environment parameters file` you created previously.
