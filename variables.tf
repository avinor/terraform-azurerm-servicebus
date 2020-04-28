variable "name" {
  description = "Name of the servicebus."
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
}

variable "location" {
  description = "The Azure Region in which to create resource."
}

variable "sku" {
  description = "The sku for the servicebus namespace"
  type        = string
  default     = "Standard"
}

variable "diagnostics" {
  description = "Diagnostic settings for those resources that support it. See README.md for details on configuration."
  type        = object({ destination = string, eventhub_name = string, logs = list(string), metrics = list(string) })
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}

variable "topics" {
  description = "Topics for the servicebus"
  type = list(object({
    name                = string,
    enable_partitioning = bool,
    default_message_ttl = string,
    keys                = list(object({ name = string, listen = bool, send = bool }))
  }))
  default = []
}

variable "authorization_rules" {
  description = "Authorization rules to add to the namespace. For topics use `topics` variable to add authorization keys."
  type        = list(object({ name = string, listen = bool, send = bool, manage = bool }))
  default     = []
}