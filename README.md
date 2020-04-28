# ServiceBus

Terraform module to deploy a servicebus on Azure 


## Usage

This example deploys a simple servicebus.

Example uses [tau](https://github.com/avinor/tau) for deployment.

```terraform
module {
  source = "github.com/avinor/terraform-azurerm-servicebus"
}

inputs {
  name                = "my-servicebus-dev"
  location            = "westeurope"
  resource_group_name = "ipt-servicebus-rg"
  sku                 = "Standard"

  topics = [
    {
      name                = "mytopic"
      default_message_ttl = "P30M"
      enable_partitioning = false

      keys = [
        {
          name   = "key1",
          listen = true,
          send   = true,
        }
      ]
    },
    {
      name = "mytopic2"
      default_message_ttl = "P30M"
      enable_partitioning = false

      keys = [
        {
          name   = "key2",
          listen = true,
          send   = true,
        }
      ]
    }
  ]
}
```

## Diagnostics
