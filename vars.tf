################
# Loadbalancer #
################
variable "lb_name" {
  description = "Human-readable name for the Loadbalancer"
  type        = string
}

variable "lb_description" {
  description = "Human-readable description for the Loadbalancer"
  type        = string
  default     = ""
}

variable "lb_vip_subnet_id" {
  description = "The network's subnet on which to allocate the Loadbalancer's address"
  type        = string
  default     = null
}

variable "lb_vip_network_id" {
  description = "The network on which to allocate the Loadbalancer's address"
  type        = string
  default     = null
}

variable "lb_vip_port_id" {
  description = "The network's port on which want to connect the loadbalancer"
  type        = string
  default     = null
}

variable "lb_vip_address" {
  description = "The ip address of the load balancer"
  type        = string
  default     = null
}

variable "lb_loadbalancer_provider" {
  description = "The name of the provider"
  type        = string
  default     = null
}

variable "lb_availability_zone" {
  description = "The availability zone of the Loadbalancer"
  type        = string
  default     = null
}

variable "lb_security_group_ids" {
  description = "A list of security group IDs to apply to the loadbalancer"
  type        = list(string)
  default     = []
}

variable "lb_flavor_id" {
  description = "Loadbalancer flavor (HA, stand-alone)"
  type        = string
  default     = null
}

variable "tags" {
  description = "A list of strings to add to the load balancer"
  type        = list(string)
  default     = []
}

################
## Listener(s) #
################
variable "listeners" {
  description = "Map with Listener(s) to create"
  type = map(object({
    listener_name                     = optional(string)
    listener_description              = optional(string)
    listener_protocol                 = string
    listener_protocol_port            = string
    listener_connection_limit         = optional(string)
    listener_timeout_client_data      = optional(string)
    listener_timeout_member_connect   = optional(string)
    listener_timeout_member_data      = optional(string)
    listener_timeout_tcp_inspect      = optional(string)
    listener_tls_container_ref        = optional(string)
    listener_sni_container_refs       = optional(list(string))
    listener_insert_headers           = optional(map(string))
    listener_allowed_cidrs            = optional(list(string))
    pool_name                         = optional(string)
    pool_description                  = optional(string)
    pool_protocol                     = string
    pool_method                       = optional(string)
    pool_sess_persistence_type        = optional(string)
    pool_sess_persistence_cookie_name = optional(string)
    monitor_name                      = optional(string)
    monitor_type                      = string
    monitor_delay                     = optional(string)
    monitor_timeout                   = optional(string)
    monitor_max_retries               = optional(string)
    monitor_max_retries_down          = optional(string)
    monitor_url_path                  = optional(string)
    monitor_http_method               = optional(string)
    monitor_expected_codes            = optional(string)
    members = optional(list(object({
      address       = string,
      protocol_port = number,
      subnet_id     = optional(string),
      name          = optional(string),
      weight        = optional(number),
      backup        = optional(bool),
    })))
  }))
}


locals {
  listeners = defaults(var.listeners, {
    listener_protocol      = "HTTP"
    listener_protocol_port = "80"
    pool_protocol          = "HTTP"
    pool_method            = "ROUND_ROBIN"
    monitor_delay          = "10"
    monitor_timeout        = "5"
    monitor_max_retries    = "3"
  })
}
