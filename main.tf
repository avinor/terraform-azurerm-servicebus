terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.94.0"
    }
  }
}

provider "azurerm" {
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

  keys = flatten([
    for t in var.topics : [
      for a in t.keys : {
        topic = t.name
        rule  = a
      }
    ]
  ])

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
  name                          = "${var.name}-sbn"
  location                      = azurerm_resource_group.sb.location
  resource_group_name           = azurerm_resource_group.sb.name
  sku                           = "Standard"
  tags                          = var.tags

  dynamic "network_rule_set" {
    for_each = [true]
    content {
      default_action           = length(var.ip_rules) > 0 ? "Deny" : "Allow"
      trusted_services_allowed = true
      ip_rules                 = length(var.ip_rules) > 0 ? var.ip_rules : null
    }
  }
}

resource "azurerm_servicebus_namespace_authorization_rule" "sb" {
  for_each = local.authorization_rules

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.sb.id

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage
}

resource "azurerm_servicebus_topic" "sb" {
  for_each = { for i in local.topics_with_defaults : i.name => i }

  name                      = each.key
  namespace_id              = azurerm_servicebus_namespace.sb.id
  enable_partitioning       = each.value.enable_partitioning
  default_message_ttl       = each.value.default_message_ttl
  auto_delete_on_idle       = each.value.auto_delete_on_idle
  enable_batched_operations = each.value.enable_batched_operations
}

resource "azurerm_servicebus_topic_authorization_rule" "sb" {
  for_each = { for i in local.keys : format("%s-%s", i.topic, i.rule.name) => i }

  name     = each.value.rule.name
  topic_id = azurerm_servicebus_topic.sb[each.value.topic].id
  listen   = each.value.rule.listen
  send     = each.value.rule.send
  manage   = each.value.rule.manage

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

  dynamic "enabled_log" {
    for_each = {
      for k, v in data.azurerm_monitor_diagnostic_categories.default.log_category_types : k => v
      if contains(local.parsed_diag.log, "all") || contains(local.parsed_diag.log, v)
    }
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.metrics
    content {
      category = metric.value
      enabled  = contains(local.parsed_diag.metric, "all") || contains(local.parsed_diag.metric, metric.value)
    }
  }

}
