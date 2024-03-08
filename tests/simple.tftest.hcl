variables {

  name                = "simple"
  resource_group_name = "simple-rg"
  location            = "westeurope"

  topics = [
    {
      name = "topic1"
      default_message_ttl = "PT30M"
      enable_partitioning = false
      keys = [
        {
          name   = "key1"
          listen = true
          send   = true
          manage = false
        }
      ]
    },
    {
      name = "topic2"
      default_message_ttl = "PT30M"
      enable_partitioning = false
      keys = [
        {
          name   = "key2"
          listen = true
          send   = true
          manage = false
        }
      ]
    },
  ]

  ip_rules = ["123.123.123.0/28", "123.123.124.0/26"]

  tags = {
    tag1 = "value1"
  }

}

run "simple" {

  command = plan

  assert {
    condition     = azurerm_resource_group.sb.name == "simple-rg"
    error_message = "Resource group name did not match expected"
  }

  assert {
    condition     = azurerm_servicebus_namespace.sb.location == "westeurope"
    error_message = "Servicebus namespace location did not match expected"
  }

  assert {
    condition     = azurerm_servicebus_namespace.sb.name == "simple-sbn"
    error_message = "Servicebus namespace name did not match expected"
  }

  assert {
    condition     = azurerm_servicebus_namespace.sb.local_auth_enabled == true
    error_message = "Servicebus namespace local_auth_enabled did not match expected"
  }

  assert {
    condition     = length(azurerm_servicebus_topic.sb) == 2
    error_message = "Number of topics did not match expected"
  }

  assert {
    condition     = azurerm_servicebus_topic.sb["topic1"].name == "topic1"
    error_message = "Topics instances did not match expected"
  }

  assert {
    condition     = azurerm_servicebus_topic.sb["topic2"].name == "topic2"
    error_message = "Topics instances did not match expected"
  }

}