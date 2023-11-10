# Terraform Module: nsg-rules

This Terraform module provides a flexible way to define and manage NSG rules in either `YAML`, `CSV`, or native Terraform variable formats.

The module accepts any combination of `YAML`, `CSV` and Terraform variable as input rules. The inputs from various sources will be merged for NSG rules creation.

## NSG Rules Specification

This module accepts the following specification for defining NSG rules:

| Key                                        | Note                                                                |
| ------------------------------------------ | :------------------------------------------------------------------ |
| name                                       | (Mandatory) Name of the rule (string)                               |
| priority                                   | (Mandatory) NSG rule priority (num)                                 |
| direction                                  | (Mandatory) Direction of the rule (either `Inbound`, or `Outbound`) |
| access                                     | Either `Deny` or `Allow`                                            |
| protocol                                   | Either `Tcp`, `Udp`, `Icmp`, `Esp`, `Ah`, or `*`                    |
| source_service_tag                         | The name of the Service Tag (string)                                |
| destination_service_tag                    | The name of the Service Tag (string)                                |
| source_port_ranges                         | List of source ports or range of ports (list)                       |
| destination_port_ranges                    | List of destination ports or range of ports (list)                  |
| source_address_prefixes                    | List of source address prefixes (list)                              |
| destination_address_prefixes               | List of destination address prefixes (list)                         |
| source_application_security_group_ids      | List of source ASG (list)                                           |
| destination_application_security_group_ids | List of destination ASG (list)                                      |
| description                                | Description of the rule (string)                                    |

When defining NSG rules, it is important to note the following requirements:

- `source_service_tag`, `source_address_prefixes`, and `source_application_security_group_ids` are mutually exclusive. Only one will be accepted. If none of them is defined, the NSG rule will default to `*` as source.
- `destination_service_tag`, `destination_address_prefixes`, and `destination_application_security_group_ids` are mutually exclusive. Only one will be accepted. If none of them is defined, the NSG rule will default to `*` as destination.
- If `source_port_ranges` is undefined, the NSG rule will default to `*` (Any).
- If `destination_port_ranges` is undefined, the NSG rule will default `*` (Any).
- If `protocol` is undefined, the NSG rule will default to `*` (Any).

**Note:** For `YAML` and `CSV` inputs, the optional fields can be omitted in the schema/definition. The module will take care of any optional fields as per the above requirements.

## Examples

Refer to the sub-directory `examples` within this repository for example usage of the module parameters.

### Using only Terraform Input Variable

#### Service Tag Usage

This example shows how to create rules using `Service Tag` and `Application Security Group`.

```terraform
module "simple_nsg" {
    source = "git::https://gitlab.com/aiyor/pub/terraform-modules/azure-nsg-rules.git?ref=v0.5.0"

    resource_group_name = "my-resource-group"
    network_security_group_name = "my-nsg"
    create_new_nsg = false # Optional: Default to False. If True, the module will create a new NSG.

    nsg_rules = [
        {
            # Mandatory inputs
            name = "nsg-01"
            priority = 1000
            direction = "Outbound"

            # Optional inputs
            access = "Allow" # Default to Deny if not defined
            source_address_prefixes = ["192.168.0.0/16","10.0.1.0/16"]
            destination_service_tag = "Internet"  # An Azure Service Tag
            destination_port_ranges = [443, 80, 22]
        },
        {
            # Mandatory inputs
            name = "nsg-02"
            priority = 1100
            direction = "Inbound"
            access = "Allow"

            # Optional inputs
            source_address_prefixes = ["10.0.1.0/16"]
            destination_application_security_group_ids = ["a-long-string-of-asg-id"] # ASG
            destination_port_ranges = [443, 80, 22]
        }
    ]
}
```

### Using YAML Configuration

This module accepts an optional variable, `yaml_conf_dir`, for users to define NSG rules in `YAML` files. It follows the concept of Linux `*.d` directories, where users can create multiple `YAML` files under the config directory to define NSG rules. The module will merge/join all the configuration defined in `YAML` under the `yaml_conf_dir` directory, and process them into Terraform 'variables'.

In this example, assume a directory `nsg_rules_dir` exists in the root module. Users can then create various `YAML` files under the directory. The module will look for all files with either `.yaml` or `.yml` extension within the directory (including sub-directories).

In the file `nsg_rules_dir/rules01.yml`:

```yaml
- name: test101
  direction: Inbound
  access: Allow
  priority: 1101
  protocol: Tcp
  source_port_ranges: "*"
  destination_port_ranges: "*"
  source_address_prefixes:
    - 10.0.0.0/8
    - 192.168.0.0/24
  destination_application_security_group_ids:
    - /subscriptions/some-long-string/resourceGroups/my-rg/providers/Microsoft.Network/applicationSecurityGroups/myasg01

- name: Test201
  direction: Outbound
  access: Allow
  priority: 2102
  protocol: Tcp
  source_address_prefixes: "192.168.0.12"
  destination_service_tag: Internet
  source_port_ranges: ["22", "443", "80"]
```

In the file `nsg_rules_dir/rules02.yml`:

```yaml
- name: test104
  direction: Inbound
  access: Allow
  priority: 1104
  source_port_ranges: ["*"]
  destination_port_ranges: ["*"] # Optional -
  destination_address_prefixes:
    - 10.0.0.0/8
    - 192.168.0.0/24
  source_application_security_group_ids:
    - /subscriptions/some-long-string/resourceGroups/my-rg/providers/Microsoft.Network/applicationSecurityGroups/myasg01
```

Then in the file `main.tf` in the root module directory:

```terraform
module "test01" {
    source = "git::https://gitlab.com/aiyor/pub/terraform-modules/azure-nsg-rules.git?ref=v0.5.0"

    resource_group_name = "my-resource-group"
        network_security_group_name = "my-nsg"


    yaml_conf_dir = "${path.module}/nsg_rules_dir"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
Copyright 2023 Tze Liang

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.75, < 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.75, < 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_security_group) | data source |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_new_nsg"></a> [create\_new\_nsg](#input\_create\_new\_nsg) | (Boolean) Create new NSG | `bool` | `false` | no |
| <a name="input_csv_conf_dir"></a> [csv\_conf\_dir](#input\_csv\_conf\_dir) | Path to the configuration directory that contains NSG rules defined in CSV file(s). | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure Region name | `string` | `"Australia East"` | no |
| <a name="input_network_security_group_name"></a> [network\_security\_group\_name](#input\_network\_security\_group\_name) | Azure Network Security Group name | `string` | n/a | yes |
| <a name="input_nsg_rules"></a> [nsg\_rules](#input\_nsg\_rules) | NSG rules input. List of object. | <pre>list(object({<br>    name                                       = string<br>    priority                                   = number<br>    direction                                  = string<br>    access                                     = optional(string, "Deny")<br>    protocol                                   = optional(string, "*")<br>    source_service_tag                         = optional(string)<br>    destination_service_tag                    = optional(string)<br>    source_port_ranges                         = optional(list(string))<br>    destination_port_ranges                    = optional(list(string))<br>    source_address_prefixes                    = optional(list(string))<br>    destination_address_prefixes               = optional(list(string))<br>    source_application_security_group_ids      = optional(list(string))<br>    destination_application_security_group_ids = optional(list(string))<br>    description                                = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure Resource Group name | `string` | n/a | yes |
| <a name="input_strict_naming"></a> [strict\_naming](#input\_strict\_naming) | (Boolean) Use strict name. i.e., Do not auto-append suffix to name. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | NSG tags. Only applicable when creating new NSG. | `map(string)` | `null` | no |
| <a name="input_yaml_conf_dir"></a> [yaml\_conf\_dir](#input\_yaml\_conf\_dir) | Path to the configuration directory that contains NSG rules defined in YAML file(s). | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nsg_attributes"></a> [nsg\_attributes](#output\_nsg\_attributes) | n/a |
| <a name="output_nsg_rules"></a> [nsg\_rules](#output\_nsg\_rules) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
