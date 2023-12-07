# Steps to use this k8s cluster cleanup tool

1. Clone this tool
2. Update all variables in `reset.sh` file, please be very careful, otherwise, you may delete wrong resources, including other's resources since subscription is shared by all team members
3. Open a bash terminal, decide which command to run
4. There're several available options to run this tool:
    - `sh ./reset.sh` to delete only Alice Springs resources inside k8s cluster, no cloud resources will be touched
    - `sh ./reset.sh -s` to delete Alice Springs resources inside k8s cluster, and all cloud resources (Symphony, Bluefin, Custom Location, Resource Sync Rule, etc.) inside the resource group you provided, *in most of the cases, you should use this option*
    - `sh ./reset.sh -a` to delete entire resource group including k8s cluster itself, *only use this option if you want to recreate your k8s cluster*
5. Follow the output and check result, you can ctrl+c to kill the process, then re-run it, report issues to <zhengzh@microsoft.com>

## Known issues

- This tool does not support multiple PAS instances running on the same k8s cluster.
- This tool assumes you do not have other workloads running on the same k8s cluster, if you do have workloads other than PAS, please do not use this tool, otherwise, you may delete components or resources unrelated to PAS.
- `PAS` has been renamed to `AIO`, this tool will delete both old PAS and new AIO resources & components.
- If you run into permission issues when deleting componenets inside the cluster, you probably did not specify `--admin` when getting credentials for your k8s cluster, please re-run `az aks get-credentials --resource-group rg --name n --admin`, make sure to append `--admin` flag.


## Alternative to updating `reset.sh` 
Set the corresponding environment variables:
```bash
export SUBSCRIPTION_ID="<<SUBSCRIPTION_ID>>"
export RESOURCE_GROUP_NAME="<<RESOURCE_GROUP_NAME>>"
export K8S_CLUSTER_NAME="<<K8S_CLUSTER_NAME>>"
export K8S_CLUSTER_CONTEXT="<<K8S_CLUSTER_CONTEXT>>"
```

Then run the following command: (using `-s`)
```bash
export resetOption="-s" && cat reset.sh | sed -e "s/<<SUBSCRIPTION_ID>>/$SUBSCRIPTION_ID/g" -e "s/<<RESOURCE_GROUP_NAME>>/$RESOURCE_GROUP_NAME/g" -e "s/<<K8S_CLUSTER_NAME>>/$K8S_CLUSTER_NAME/g" -e "s/<<K8S_CLUSTER_CONTEXT>>/$K8S_CLUSTER_CONTEXT/g"| envsubst '$resetOption' | sh
```