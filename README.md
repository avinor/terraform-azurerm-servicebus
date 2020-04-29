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
  name                = "simple"
  location            = "westeurope"
  resource_group_name = "servicebus-simple-rg"
  sku                 = "Standard"

  topics = [
    {
      name                = "mytopic"
      default_message_ttl = "PT30M"
      enable_partitioning = false

      keys = [
        {
          name   = "key1",
          listen = true,
          send   = true,
        }
      ]
    }
  ]
}
```

Output from the module is the servicebus namespace id and a map topics and primary and secondary keys for each entry in key list.
For this simple example would be :
```
id = /subscriptions/{subscription_id}/resourceGroups/servicebus-simple-rg/providers/Microsoft.ServiceBus/namespaces/simple-sbn

keys = {
    "key1" = {
        "primary_key" = "..."
        "secondary_key" = "..."
    }
}

topic_ids = {
  "0" = "/subscriptions/{subscription_id}/resourceGroups/servicebus-simple-rg/providers/Microsoft.ServiceBus/namespaces/simple-sbn/topics/mytopic"
}


```

## Diagnostics

Diagnostics settings can be sent to either storage account, event hub or Log Analytics workspace. The variable diagnostics.destination is the id of receiver, ie. storage account id, event namespace authorization rule id or log analytics resource id. Depending on what id is it will detect where to send. Unless using event namespace the eventhub_name is not required, just set to null for storage account and log analytics workspace.

Setting all in logs and metrics will send all possible diagnostics to destination. If not using all type name of categories to send.