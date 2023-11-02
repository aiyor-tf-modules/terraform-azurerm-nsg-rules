module "test01" {
  source = "../../"

  resource_group_name         = "rg"
  network_security_group_name = "my-nsg"

  yaml_conf_dir = "${path.module}/nsg_rules"
  csv_conf_dir  = "${path.module}/nsg_rules"
}

output "nsg_rules" {
  value = module.test01.nsg_rules
}

output "nsg_attributes" {
  value = module.test01.nsg_attributes
}
