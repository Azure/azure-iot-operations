# azure-iot-operations

## Overview

This repo contains the definition of Azure IoT Operations (AIO) and allows for
AIO to be deployed to an Arc-enabled K8s cluster.

Please follow the Azure IoT Operations [Quickstart](https://alicesprings.ms/docs/quickstart/)

## Forking the Repo

If you want to fork this repo, there are some additional steps you will need to take to set up the fork.

1. Set the `AZURE_CREDENTIALS` repository secret.

    1. Create a Service Principal resource for the repository to use when performing GitHub actions.
        ```
        // If you haven't upgraded your Azure CLI lately, run the following.
        az upgrade

        // Create a Service Principal to perform operations on the provided subscription.
        az ad sp create-for-rbac --name <sp-name> --role owner --scopes /subscriptions/<subscription-id> --json-auth
        ```

    2. Copy the JSON output from the Service Principal creation command and paste into a repository secret named `AZURE_CREDENTIALS`
        in your fork. Repository secrets can be found under "Settings > Secrets and 
       variables > Actions." To learn more, see [creating secrets for a repository](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository).

2. [Optional] If testing scenarios for AIO that require credentials, create Azure Key Vault and create SP and give permissions on KV

    1. Identify secrets required for scenario and put them in the Azure Key Vault.

3. Create and setup K8s Arc-enabled cluster.

    1. If K8s cluster does not already exist, create it.

    2. Arc-enable cluster.

    3. Run cluster setup script from `tools/setup-cluster/`.

4. Deploy Azure IoT Operations.

    1. Create parameter file where environment configuration is specified for your AIO deployment. For an example, see `environments/example.parameters.json`.

    | **Parameter** | **Value**                  |
    | ------------- | -------------------------- |
    | clusterName   | [Required] The Arc-enabled cluster resource in Azure.  |
    | clusterLocation | [Optional] If the cluster resource's location is different than its resource group's location, the cluster location will need to be specified. Otherwise, this parameter will default to the location of the resource group.  |
    | location      | [Optional] If the resource group's location is not a supported AIO region, this parameter can be used to override the location of the AIO resources. |
    | dataProcessorSecrets | [Optional] ... |
    | mqSecrets | [Optional] ... |
    | opcUaBrokerSecrets | [Optional] ... |

    2. Run the **GitOps Deployment of Azure IoT Operations** GitHub Action.