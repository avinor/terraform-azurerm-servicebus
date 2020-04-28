# ServiceBus

Terraform module to deploy a servicebus on Azure 


## Usage

This example deploys a simple servicebus.

Example uses [tau](https://github.com/avinor/tau) for deployment.

```terraform
module {
    source = "avinor/servicebus/azurerm"
    version = "1.0.0"
}

inputs {
}
```

## Diagnostics
