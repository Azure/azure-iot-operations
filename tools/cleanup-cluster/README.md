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
