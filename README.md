# azure-iot-operations

## Overview

This repo contains the definition of Azure IoT Operations (AIO) and allows for
AIO to be deployed to an Arc-enabled K8s cluster.

Please follow the Azure IoT Operations [Quickstart](https://alicesprings.ms/docs/quickstart/)

## Forking the Repo

If you want to fork this repo, there are some additional steps you will need to take to set up the fork.

1. Set the `AZURE_CREDENTIALS` repository secrets.
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