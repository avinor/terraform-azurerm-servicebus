output "id" {
  description = "The Servicbus namespace ID."
  value       = azurerm_servicebus_namespace.sb.id
}

output "topic_ids" {
  description = "Map of topics and their ids."
  value       = { for k, v in azurerm_servicebus_topic.sb : k => v.id }
}

output "keys" {
  description = "Map of hubs with keys => primary_key / secondary_key mapping."
  sensitive   = true
  value = { for k, h in azurerm_servicebus_topic_authorization_rule.sb : h.name => {
    primary_key   = h.primary_key
    secondary_key = h.secondary_key
    }
  }
}

output "authorization_keys" {
  description = "Map of authorization keys with their ids."
  value       = { for a in azurerm_servicebus_namespace_authorization_rule.sb : a.name => a.id }
}