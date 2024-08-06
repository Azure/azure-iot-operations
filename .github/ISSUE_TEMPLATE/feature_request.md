name: ✨ Feature request
description: Suggest a new feature or improvement
title: '[Feature]: '
labels: [feature-request, needs-triage]

body:
- type: markdown
  attributes:
    value: >
      Thanks for reporting.
      
      - Please search the existing feature requests to see if there has been a similar issue filed.
- type: textarea
  attributes:
    label: Is your feature request related to a problem? Please describe.
    description: >
      A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]
  validations:
    required: true
- type: textarea
  attributes:
    label: Describe the solution you'd like
    description: >
      A clear and concise description of what you want to happen.
  validations:
    required: true
- type: textarea
  attributes:
    label: Proposed implementation details (optional)
  validations:
    required: false
- type: textarea
  attributes:
    label: Describe alternatives you've considered (optional)
    description: >
      A clear and concise description of any alternative solutions or features you've considered.
  validations:
    required: false