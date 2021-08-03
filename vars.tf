###########
# General #
###########
variable "name" {
  description = "Name to prefix all resources created on OpenStack"
  type        = string
}

################
# Loadbalancer #
################
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

variable "lb_vip_port_id" {
  description = "The network's port on which want to connect the loadbalancer"
  type        = string
  default     = null
}

variable "lb_security_group_ids" {
  description = "A list of security group IDs to apply to the loadbalancer"
  type        = list(string)
  default     = []
}

################
## Listener(s) #
################
variable "listeners" {
  type = any
}

variable "def_values" {
  type = object({
    listener_protocol               = string
    listener_protocol_port          = string
    listener_connection_limit       = string
    lb_pool_protocol                = string
    lb_pool_method                  = string
    lb_sess_persistence             = string
    lb_sess_persistence_cookie_name = string
    monitor_url_path                = string
    monitor_expected_codes          = string
    monitor_delay                   = string
    monitor_timeout                 = string
    monitor_max_retries             = string
    monitor_max_retries_down        = string
    member_address                  = list(string)
    member_name                     = list(string)
    member_subnet_id                = string
    member_port                     = string
    tls_container_ref               = string
  })
  default = {
    listener_protocol               = "HTTP"
    listener_protocol_port          = "80"
    listener_connection_limit       = "-1"
    lb_pool_protocol                = "HTTP"
    lb_pool_method                  = "ROUND_ROBIN"
    lb_sess_persistence             = null
    lb_sess_persistence_cookie_name = null
    monitor_url_path                = "/"
    monitor_expected_codes          = "200"
    monitor_delay                   = "20"
    monitor_timeout                 = "10"
    monitor_max_retries             = "5"
    monitor_max_retries_down        = "3"
    member_address                  = []
    member_name                     = []
    member_subnet_id                = ""
    member_port                     = "80"
    tls_container_ref               = null
  }
}
