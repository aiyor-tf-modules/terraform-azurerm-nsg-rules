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

variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure Region name"
  type        = string
  default     = "Australia East"
}

variable "network_security_group_name" {
  description = "Azure Network Security Group name"
  type        = string
}

variable "create_new_nsg" {
  description = "(Boolean) Create new NSG"
  type        = bool
  default     = false
}

variable "tags" {
  description = "NSG tags. Only applicable when creating new NSG."
  type        = map(string)
  default     = null
}

variable "nsg_rules" {
  description = "NSG rules input. List of object."
  type = list(object({
    name                                       = string
    priority                                   = number
    direction                                  = string
    access                                     = optional(string, "Deny")
    protocol                                   = optional(string, "*")
    source_service_tag                         = optional(string)
    destination_service_tag                    = optional(string)
    source_port_ranges                         = optional(list(string))
    destination_port_ranges                    = optional(list(string))
    source_address_prefixes                    = optional(list(string))
    destination_address_prefixes               = optional(list(string))
    source_application_security_group_ids      = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
    description                                = optional(string)
  }))
  default = []
}

variable "strict_naming" {
  description = "(Boolean) Use strict name. i.e., Do not auto-append suffix to name."
  type        = bool
  default     = false
}

variable "yaml_conf_dir" {
  description = "Path to the configuration directory that contains NSG rules defined in YAML file(s)."
  type        = string
  default     = null
}

variable "csv_conf_dir" {
  description = "Path to the configuration directory that contains NSG rules defined in CSV file(s)."
  type        = string
  default     = null
}
