#####################
### Load balancer ###
#####################
variable "lb_name" {
  description = "Human-readable name for the load balancer"
  type        = string
}

variable "lb_description" {
  description = "Human-readable description for the load balancer"
  type        = string
  default     = ""
}

variable "lb_vip_subnet_id" {
  description = "The network's subnet on which to allocate the load balancer's address"
  type        = string
  default     = null
}

variable "lb_vip_network_id" {
  description = "The network on which to allocate the load balancer's address"
  type        = string
  default     = null
}

variable "lb_vip_port_id" {
  description = "The network's port on which want to connect the loadbalancer"
  type        = string
  default     = null
}

variable "lb_vip_address" {
  description = "The fixed VIP IP address of the load balancer"
  type        = string
  default     = null
}

variable "lb_loadbalancer_provider" {
  description = "The Octavia provider driver name"
  type        = string
  default     = null
}

variable "lb_availability_zone" {
  description = "The availability zone of the load balancer"
  type        = string
  default     = null
}

variable "lb_flavor_id" {
  description = "Load balancer flavor (HA, stand-alone)"
  type        = string
  default     = null
}

variable "lb_vip_qos_policy_id" {
  description = "The ID of the QoS Policy which will be applied to the VIP port"
  type        = string
  default     = null
}

variable "admin_state_up" {
  description = "Load balancer admin state"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A list of strings to add to the load balancer"
  type        = list(string)
  default     = []
  nullable    = false
}

###################
### Listener(s) ###
###################
variable "listeners" {
  description = <<EOT
Map of listeners to create, keyed by a logical listener name
- default_pool_key (optional) must reference a key in var.pools map
EOT
  type = map(object({
    name                        = optional(string)
    description                 = optional(string)
    protocol                    = string
    protocol_port               = number
    connection_limit            = optional(number)
    timeout_client_data         = optional(number)
    timeout_member_connect      = optional(number)
    timeout_member_data         = optional(number)
    timeout_tcp_inspect         = optional(number)
    default_tls_container_ref   = optional(string)
    sni_container_refs          = optional(list(string), [])
    insert_headers              = optional(map(string), {})
    allowed_cidrs               = optional(list(string), [])
    client_authentication       = optional(string)
    client_ca_tls_container_ref = optional(string)
    client_crl_container_ref    = optional(string)
    tls_ciphers                 = optional(string)
    tls_versions                = optional(list(string), [])
    tags                        = optional(list(string), [])
    default_pool_key            = optional(string)
    admin_state_up              = optional(bool, true)
  }))
  default = {}
}

#############
### Pools ###
#############
variable "pools" {
  description = <<EOT
Map of pools keyed where each key represents a unique pool name
- Each pool may define session_persistence, an optional monitor, and a map of members.
- The members map keys are logical identifiers for each member.
EOT
  type = map(object({
    name        = optional(string)
    description = optional(string)
    protocol    = string
    lb_method   = optional(string, "ROUND_ROBIN")

    persistence = optional(object({
      type        = string
      cookie_name = optional(string)
    }))

    monitor = optional(object({
      name             = optional(string)
      type             = string
      delay            = number
      timeout          = number
      max_retries      = number
      max_retries_down = optional(number)
      url_path         = optional(string)
      http_method      = optional(string)
      http_version     = optional(string)
      expected_codes   = optional(string)
      admin_state_up   = optional(bool, true)
    }))

    members = optional(map(object({
      name            = optional(string)
      address         = string
      protocol_port   = number
      subnet_id       = optional(string)
      weight          = optional(number)
      monitor_port    = optional(number)
      monitor_address = optional(string)
      backup          = optional(bool)
      tags            = optional(list(string), [])
    })), {})
  }))
  default  = {}
  nullable = false
}

###################
### L7 policies ###
###################
variable "l7policies" {
  description = <<EOT
Map of listener-key => map of L7 policies. Policies can redirect to URL or to a pool (by pool key).
- The listener_key must match a key from var.listeners map.
- The policy_key is a logical identifier for the policy (e.g., redirect-rule).
- redirect_pool_key (optional) must reference a valid key from var.pools map.
- Each policy can contain a nested map of rules, where each key is a logical identifier for the rule.
EOT
  type = map(map(object({
    name               = optional(string)
    description        = optional(string)
    action             = string
    position           = number
    redirect_url       = optional(string)
    redirect_pool_key  = optional(string)
    redirect_prefix    = optional(string)
    redirect_http_code = optional(number)
    admin_state_up     = optional(bool, true)

    rules = optional(map(object({
      type           = string
      compare_type   = string
      value          = string
      key            = optional(string)
      invert         = optional(bool, false)
      admin_state_up = optional(bool, true)
    })), {})
  })))
  default = {}
}
