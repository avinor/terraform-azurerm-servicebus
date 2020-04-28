terraform {
  required_version = ">= 0.12.6"
}

provider azurerm {
  version = "~>2.7.0"
  features {}
}

locals {
  default_topic = {
    enable_partitioning       = false
    default_message_ttl       = null
    auto_delete_on_idle       = null
    enable_batched_operations = null
    keys                      = []
  }

  topics_with_defaults = [for t in var.topics :
    merge(local.default_topic, t)
  ]

  keys = { for tk in flatten([for h in var.topics :
    [for k in h.keys : {
      topic = h.name
      key   = k
  }]]) : format("%s.%s", tk.topic, tk.key.name) => tk }

  authorization_rules = { for a in var.authorization_rules : a.name => a }
}

resource "azurerm_resource_group" "sb" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_servicebus_namespace" "sb" {
  name                = "${var.name}-sbn"
  location            = azurerm_resource_group.sb.location
  resource_group_name = azurerm_resource_group.sb.name
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_servicebus_namespace_authorization_rule" "sb" {
  for_each = local.authorization_rules

  name                = each.key
  namespace_name      = azurerm_servicebus_namespace.sb.name
  resource_group_name = azurerm_resource_group.sb.name

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage
}

resource "azurerm_servicebus_topic" "sb" {
  count = length(local.topics_with_defaults)

  namespace_name      = azurerm_servicebus_namespace.sb.name
  resource_group_name = azurerm_resource_group.sb.name

  name                      = local.topics_with_defaults[count.index].name
  enable_partitioning       = local.topics_with_defaults[count.index].enable_partitioning
  default_message_ttl       = local.topics_with_defaults[count.index].default_message_ttl
  auto_delete_on_idle       = local.topics_with_defaults[count.index].auto_delete_on_idle
  enable_batched_operations = local.topics_with_defaults[count.index].enable_batched_operations
}


resource "azurerm_servicebus_topic_authorization_rule" "sb" {
  for_each = local.keys

  name                = each.value.key.name
  namespace_name      = azurerm_servicebus_namespace.sb.name
  topic_name          = each.value.topic
  resource_group_name = azurerm_resource_group.sb.name

  listen = each.value.key.listen
  send   = each.value.key.send
  manage = false

  depends_on = [azurerm_servicebus_topic.sb]
}