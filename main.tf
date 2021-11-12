############################
### Create load balancer ###
############################
resource "openstack_lb_loadbalancer_v2" "loadbalancer" {
  name               = "${var.name}-loadbalancer"
  description        = var.lb_description
  vip_subnet_id      = var.lb_vip_subnet_id
  vip_port_id        = var.lb_vip_port_id
  security_group_ids = var.lb_security_group_ids
  flavor_id          = var.lb_flavor_id
  admin_state_up     = "true"
}

######################
### Create pool(s) ###
######################
resource "openstack_lb_pool_v2" "lb_pool" {
  for_each = var.listeners

  description     = var.lb_description
  name            = lookup(each.value, "lb_pool_name", format("%s-%s-%s", var.name, each.key, "lb_pool"))
  protocol        = lookup(each.value, "lb_pool_protocol", var.def_values.lb_pool_protocol)
  lb_method       = lookup(each.value, "lb_pool_method", var.def_values.lb_pool_method)
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id

  dynamic "persistence" {
    for_each = contains(keys(each.value), "lb_sess_persistence") ? tolist([each.value["lb_sess_persistence"]]) : []
    content {
      type        = persistence.value
      cookie_name = lookup(each.value, "lb_sess_persistence_cookie_name", var.def_values.lb_sess_persistence_cookie_name)
    }
  }
}

##########################
### Create listener(s) ###
##########################
resource "openstack_lb_listener_v2" "listener" {
  for_each = var.listeners

  description               = var.lb_description
  name                      = lookup(each.value, "listener_name", format("%s-%s-%s", var.name, each.key, "listener"))
  protocol                  = lookup(each.value, "listener_protocol", var.def_values.listener_protocol)
  protocol_port             = lookup(each.value, "listener_protocol_port", var.def_values.listener_protocol_port)
  connection_limit          = lookup(each.value, "listener_connection_limit", var.def_values.listener_connection_limit)
  default_tls_container_ref = lookup(each.value, "tls_container_ref", var.def_values.tls_container_ref)
  admin_state_up            = "true"
  loadbalancer_id           = openstack_lb_loadbalancer_v2.loadbalancer.id
  default_pool_id           = openstack_lb_pool_v2.lb_pool[each.key].id
}

locals {
  non_http = ["TCP", "PROXY"]
}

#########################
### Create monitor(s) ###
#########################
# monitor has different parameters to http* and tcp
# Create non TCP monitor
resource "openstack_lb_monitor_v2" "lb_monitor" {
  for_each = { for k, r in var.listeners : k => r if !contains(local.non_http, r["lb_pool_protocol"]) }

  pool_id          = openstack_lb_pool_v2.lb_pool[each.key].id
  name             = lookup(each.value, "monitor_name", format("%s-%s-%s", var.name, each.key, "lb_monitor"))
  type             = lookup(each.value, "lb_pool_protocol", var.def_values.lb_pool_protocol)
  url_path         = lookup(each.value, "monitor_url_path", var.def_values.monitor_url_path)
  expected_codes   = lookup(each.value, "monitor_expected_codes", var.def_values.monitor_expected_codes)
  delay            = lookup(each.value, "monitor_delay", var.def_values.monitor_delay)
  timeout          = lookup(each.value, "monitor_timeout", var.def_values.monitor_timeout)
  max_retries      = lookup(each.value, "monitor_max_retries", var.def_values.monitor_max_retries)
  max_retries_down = lookup(each.value, "monitor_max_retries_down", var.def_values.monitor_max_retries_down)
}

# Create TCP monitor
resource "openstack_lb_monitor_v2" "lb_monitor_tcp" {
  for_each = { for k, r in var.listeners : k => r if contains(local.non_http, r["lb_pool_protocol"]) }

  pool_id          = openstack_lb_pool_v2.lb_pool[each.key].id
  name             = lookup(each.value, "monitor_name", format("%s-%s-%s", var.name, each.key, "lb_monitor"))
  type             = lookup(each.value, "listener_protocol", var.def_values.listener_protocol)
  delay            = lookup(each.value, "monitor_delay", var.def_values.monitor_delay)
  timeout          = lookup(each.value, "monitor_timeout", var.def_values.monitor_timeout)
  max_retries      = lookup(each.value, "monitor_max_retries", var.def_values.monitor_max_retries)
  max_retries_down = lookup(each.value, "monitor_max_retries_down", var.def_values.monitor_max_retries_down)
}

################################
### Add member(s) to pool(s) ###
################################
resource "openstack_lb_members_v2" "members" {
  for_each = { for k, r in var.listeners : k => r if contains(keys(r), "member_address") }

  pool_id = openstack_lb_pool_v2.lb_pool[each.key].id

  dynamic "member" {
    # If member_name is specified, it creates a map name: ip, otherwise ip: ip
    for_each = contains(keys(each.value), "member_name") ? zipmap(each.value.member_name, each.value.member_address) : zipmap(each.value.member_address, each.value.member_address)
    content {
      name          = member.key
      address       = member.value
      subnet_id     = each.value.member_subnet_id
      protocol_port = lookup(each.value, "member_port", var.def_values.member_port)
    }
  }
}
