name: 🐞 Bug report
description: Report errors or unexpected behaviors of Azure IoT Operations.
labels: [needs-triage, bug]

body:
- type: markdown
  attributes:
    value: >
      Thanks for reporting.

      - Make sure you are able to reproduce this issue on the latest released version of [Azure IoT Operations](https://github.com/Azure/azure-iot-operations/releases).
      
      - Please search the existing issues to see if there has been a similar issue filed
- type: textarea
  attributes:
    label: Description
    description: >
      Please describe the issue and expected result. Please paste error script to next "Debug output" section 
  validations:
    required: true
- type: textarea
  attributes:
    label: To Reproduce
    description: >
      Steps to reproduce the behavior:
  validations:
    required: true
- type: textarea
  attributes:
    label: Issue script & Debug output
    description: >
      **⚠ ATTENTION:** Be sure to remove any sensitive information that may be in the logs
    render: PowerShell
    placeholder: |
      PS> ...
  validations:
    required: false
- type: textarea
  attributes:
    label: Environment data
    description: >
      Please run `az version` and paste the output in the below textarea.
    render: PowerShell
    placeholder: |
      PS> {"azure-cli": "x.x.x", "extensions": {"azure-iot-ops": "x.x.x"} }
  validations:
    required: false