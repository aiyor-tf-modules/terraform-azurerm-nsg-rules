/**
 * Copyright 2023 Tze Liang
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  _factory_rule_yaml_files = [
    for f in try(fileset(var.yaml_conf_dir, "**/*.{yaml,yml}"), []) :
    "${var.yaml_conf_dir}/${f}"
  ]

  _factory_rule_csv_files = [
    for f in try(fileset(var.csv_conf_dir, "**/*.csv"), []) :
    "${var.csv_conf_dir}/${f}"
  ]

  _factory_rule_csv_raw = flatten([
    for f in flatten(local._factory_rule_csv_files) : try(csvdecode(file(f)), [])
  ])

  _factory_rule_csv_process = [
    for e in local._factory_rule_csv_raw : merge(e,
      {
        source_address_prefixes = try(e.source_address_prefixes == ""
          ? null
          : e.source_address_prefixes,
        null)
        destination_address_prefixes = try(e.destination_address_prefixes == ""
          ? null
          : e.destination_address_prefixes,
        null)
        source_application_security_group_ids = try(e.source_application_security_group_ids == ""
          ? null
          : e.source_application_security_group_ids,
        null)
        destination_application_security_group_ids = try(e.destination_application_security_group_ids == ""
          ? null
          : e.destination_application_security_group_ids,
        null)
      }
    )
  ]

  _factory_rule_csv = [
    for e in local._factory_rule_csv_process : merge(e,
      {
        source_port_ranges = try(e.source_port_ranges == ""
          ? null
          : [for i in split(",", e.source_port_ranges) : trimspace(i)],
        null)
        destination_port_ranges = try(e.destination_port_ranges == ""
          ? null
          : [for i in split(",", e.destination_port_ranges) : trimspace(i)],
        null)
        source_address_prefixes = (e.source_address_prefixes == null
          ? null
          : [for i in split(",", e.source_address_prefixes) : trimspace(i)]
        )
        destination_address_prefixes = (e.destination_address_prefixes == null
          ? null
          : [for i in split(",", e.destination_address_prefixes) : trimspace(i)]
        )
        source_application_security_group_ids = (e.source_application_security_group_ids == null
          ? null
          : [for i in split(",", e.source_application_security_group_ids) : trimspace(i)]
        )
        destination_application_security_group_ids = (e.destination_application_security_group_ids == null
          ? null
          : [for i in split(",", e.destination_application_security_group_ids) : trimspace(i)]
        )
      }
    )
  ]

  _factory_rule_list = flatten(
    [
      [for f in local._factory_rule_yaml_files : try(yamldecode(file(f)), [])],
      local._factory_rule_csv,
      var.nsg_rules,
    ]
  )


  # Rules input treatment:
  # For {source,destination}_port_ranges, if the input is "*", this treatment will use
  #   {source,destination}_port_range (singular) as argument for the resource.
  # For {source,destination}_address_prefixes, if input is "*", this treatment will use
  #   {source,destination}_address_prefix (singular) as argument for the resource.
  # If {source,destination}_service_tag is defined, then
  #   {source,destination}_address_prefix (singular will be used as argument for the
  #   resource
  #
  # Note: These treatments are required because the Azure provider can only accept
  #   "*" for using the singular range/prefix arguments (ranges/prefixes list arguments
  #   do not accept "*").  Also, only singular prefix arguements are able to use
  #   service tags as input.
  nsg_rules = {
    for e in local._factory_rule_list : "${lower(e.direction)}_${e.priority}" => merge(e,
      {
        protocol = title(e.protocol)
        source_port_range = (
          length(try(flatten([e.source_port_ranges]), [])) == 0 || try(e.source_port_ranges, null) == null # if source_port_ranges is not defined, then assign "*" to source_port_range
          ? "*"
          : try(                                                         # else if source_port_ranges is "*", then assign "*" to source_port_range
            contains(flatten([e.source_port_ranges]), "*") ? "*" : null, # else assign null
            null
          )
        )
        source_port_ranges = (
          try(
            contains(flatten([e.source_port_ranges]), "*")
            ? null
            : try(flatten(e.source_port_ranges), null),
            null
          )
        )
        destination_port_range = (
          length(try(flatten([e.destination_port_ranges]), [])) == 0 || try(e.destination_port_ranges, null) == null
          ? "*"
          : try(
            contains(flatten([e.destination_port_ranges]), "*") ? "*" : null,
            null
          )
        )
        destination_port_ranges = (
          try(
            contains(flatten([e.destination_port_ranges]), "*")
            ? null
            : try(flatten(e.destination_port_ranges), null),
            null
          )
        )
        source_address_prefix = (
          try(
            e.source_service_tag,                                                                                                    # if source_service_tag is defined, then assign value of source_value_tag to source_address_prefix
            length(try(flatten([e.source_address_prefixes]), [])) == 0 || try(flatten([e.source_address_prefixes])[0], null) == null # else if source_address_prefixes is undefined, then assign "*" to source_address_prefix
            ? "*"
            : try(
              contains(flatten([e.source_address_prefixes]), "*") ? "*" : null, # else if source_address_prefixes is "*", then assign "*" to source_address_prefix
              null                                                              # else assign null
            )
          )
        )
        source_address_prefixes = (
          try(e.source_service_tag, null) == null
          ? try(
            contains(flatten([e.source_address_prefixes]), "*") || try(flatten([e.source_address_prefixes])[0], null) == null ? null : flatten([e.source_address_prefixes]),
            null
          )
          : null
        )
        destination_address_prefix = (
          try(
            e.destination_service_tag,
            length(try(flatten([e.destination_address_prefixes]), [])) == 0 || try(flatten([e.destination_address_prefixes])[0], null) == null # else if source_address_prefixes is undefined, then assign "*" to source_address_prefix
            ? "*"
            : try(
              contains(flatten([e.destination_address_prefixes]), "*") ? "*" : null,
              null
            )
          )
        )
        destination_address_prefixes = (
          try(e.destination_service_tag, null) == null
          ? try(
            contains(flatten([e.destination_address_prefixes]), "*") || try(flatten([e.destination_address_prefixes])[0], null) == null ? null : flatten([e.destination_address_prefixes]),
            null
          )
          : null
        )
      }
    )
  }

  nsg_name = var.create_new_nsg ? azurerm_network_security_group.this[0].name : data.azurerm_network_security_group.this[0].name
}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_network_security_group" "this" {
  count               = var.create_new_nsg ? 1 : 0
  name                = var.network_security_group_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = var.tags
}

data "azurerm_network_security_group" "this" {
  count               = var.create_new_nsg ? 0 : 1
  name                = var.network_security_group_name
  resource_group_name = data.azurerm_resource_group.this.name
}

# Consider using only prefixes and ranges.
# Should handle singular input for prefix and range, i.e., string input instead of list(string)
#   - The above will require handling string to list(string) conversion
#   - The above will require nested list - so require flatten list
resource "azurerm_network_security_rule" "this" {
  for_each                                   = local.nsg_rules
  name                                       = var.strict_naming ? each.value.name : "${each.value.name}_${each.value.priority}"
  priority                                   = try(each.value.priority, null)
  direction                                  = try(title(each.value.direction), null)
  access                                     = try(title(each.value.access), "Deny") # Default to Deny
  protocol                                   = try(title(each.value.protocol), "*")  # Default to Any
  source_port_range                          = try(each.value.source_port_range, null)
  destination_port_range                     = try(each.value.destination_port_range, null)
  source_port_ranges                         = try(each.value.source_port_ranges, null)
  destination_port_ranges                    = try(each.value.destination_port_ranges, null)
  source_address_prefix                      = try(each.value.source_application_security_group_ids, null) == null ? each.value.source_address_prefix : null
  destination_address_prefix                 = try(each.value.destination_application_security_group_ids, null) == null ? each.value.destination_address_prefix : null
  source_address_prefixes                    = try(each.value.source_application_security_group_ids, null) == null ? each.value.source_address_prefixes : null
  destination_address_prefixes               = try(each.value.destination_application_security_group_ids, null) == null ? each.value.destination_address_prefixes : null
  source_application_security_group_ids      = try(each.value.source_application_security_group_ids, null)
  destination_application_security_group_ids = try(each.value.destination_application_security_group_ids, null)
  description                                = try(each.value.description, null)
  resource_group_name                        = data.azurerm_resource_group.this.name
  network_security_group_name                = local.nsg_name

  lifecycle {
    create_before_destroy = false
  }
}
