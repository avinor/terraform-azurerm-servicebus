terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.53.0"
    }
  }
}

provider azurerm {
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

  diag_resource_list = var.diagnostics != null ? split("/", var.diagnostics.destination) : []
  parsed_diag = var.diagnostics != null ? {
    log_analytics_id   = contains(local.diag_resource_list, "Microsoft.OperationalInsights") ? var.diagnostics.destination : null
    storage_account_id = contains(local.diag_resource_list, "Microsoft.Storage") ? var.diagnostics.destination : null
    event_hub_auth_id  = contains(local.diag_resource_list, "Microsoft.EventHub") ? var.diagnostics.destination : null
    metric             = var.diagnostics.metrics
    log                = var.diagnostics.logs
    } : {
    log_analytics_id   = null
    storage_account_id = null
    event_hub_auth_id  = null
    metric             = []
    log                = []
  }

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

resource "azurerm_servicebus_namespace_network_rule_set" "sb" {
  count = length(var.ip_rules) + length(var.network_rules) > 0 ? 1 : 0

  namespace_name      = azurerm_servicebus_namespace.sb.name
  resource_group_name = azurerm_resource_group.sb.name

  default_action = "Deny"
  ip_rules       = var.ip_rules

  dynamic "network_rules" {
    for_each = var.network_rules
    content {
      subnet_id                            = network_rules.value["subnet_id"]
      ignore_missing_vnet_service_endpoint = network_rules.value["ignore_missing_vnet_service_endpoint"]
    }
  }
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
  manage = each.value.key.manage

  depends_on = [azurerm_servicebus_topic.sb]
}

data "azurerm_monitor_diagnostic_categories" "default" {
  resource_id = azurerm_servicebus_namespace.sb.id
}

resource "azurerm_monitor_diagnostic_setting" "namespace" {
  count                          = var.diagnostics != null ? 1 : 0
  name                           = "${var.name}-ns-diag"
  target_resource_id             = azurerm_servicebus_namespace.sb.id
  log_analytics_workspace_id     = local.parsed_diag.log_analytics_id
  eventhub_authorization_rule_id = local.parsed_diag.event_hub_auth_id
  eventhub_name                  = local.parsed_diag.event_hub_auth_id != null ? var.diagnostics.eventhub_name : null
  storage_account_id             = local.parsed_diag.storage_account_id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.logs
    content {
      category = log.value
      enabled  = contains(local.parsed_diag.log, "all") || contains(local.parsed_diag.log, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.metrics
    content {
      category = metric.value
      enabled  = contains(local.parsed_diag.metric, "all") || contains(local.parsed_diag.metric, metric.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
}
