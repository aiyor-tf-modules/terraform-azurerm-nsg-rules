locals {
  string         = "this is a string"
  list_of_string = ["this is a string in a list"]
  sample_input_rules = [
    {
      name                   = "test123"
      priority               = 100
      direction              = "Outbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_port_range      = "*"
      destination_port_range = "*"
      source_address_prefix  = "*"
      #      destination_address_prefix = "*"
    },
    {
      name                       = "test456"
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "test123"
      priority                   = 300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]

  nsg_rules = {
    for e in local.sample_input_rules : "${e.name}_${e.direction}" => e
  }
}
