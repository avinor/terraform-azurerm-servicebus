module "servicebus" {

  source = "../../"

  name                = "simple"
  resource_group_name = "simple-rg"
  location            = "westeurope"

  topics = [
    {
      name                = "mytopic"
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
    }
  ]

  ip_rules = ["10.10.10.0/24"]

  tags = {
    tag1 = "value1"
  }

}
