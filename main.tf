############################
### Create load balancer ###
############################
resource "openstack_lb_loadbalancer_v2" "loadbalancer" {
  name                  = var.lb_name
  description           = var.lb_description
  vip_subnet_id         = var.lb_vip_subnet_id
  vip_network_id        = var.lb_vip_network_id
  vip_port_id           = var.lb_vip_port_id
  vip_address           = var.lb_vip_address
  loadbalancer_provider = var.lb_loadbalancer_provider
  availability_zone     = var.lb_availability_zone
  security_group_ids    = var.lb_security_group_ids
  flavor_id             = var.lb_flavor_id
  tags                  = var.tags
  admin_state_up        = "true"
}


######################
### Create pool(s) ###
######################
resource "openstack_lb_pool_v2" "lb_pool" {
  for_each = local.listeners

  description     = each.value.pool_description != null ? each.value.pool_description : format("LB: %s listener: %s", var.lb_name, each.key)
  name            = each.value.pool_name != null ? each.value.pool_name : format("%s - %s", var.lb_name, each.key)
  protocol        = each.value.pool_protocol
  lb_method       = each.value.pool_method
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id

  dynamic "persistence" {
    for_each = each.value.pool_sess_persistence_type == null ? [] : [true]
    content {
      type        = each.value.pool_sess_persistence_type
      cookie_name = each.value.pool_sess_persistence_cookie_name
    }
  }
}

##########################
### Create listener(s) ###
##########################
resource "openstack_lb_listener_v2" "lb_listener" {
  for_each = local.listeners

  description               = each.value.listener_description != null ? each.value.listener_description : format("LB: %s listener: %s", var.lb_name, each.key)
  name                      = each.value.listener_name != null ? each.value.listener_name : format("%s-%s-%s", var.lb_name, "listener", each.key)
  protocol                  = each.value.listener_protocol
  protocol_port             = each.value.listener_protocol_port
  connection_limit          = each.value.listener_connection_limit
  timeout_client_data       = each.value.listener_timeout_client_data
  timeout_member_connect    = each.value.listener_timeout_member_connect
  timeout_member_data       = each.value.listener_timeout_member_data
  timeout_tcp_inspect       = each.value.listener_timeout_tcp_inspect
  default_tls_container_ref = each.value.listener_tls_container_ref
  sni_container_refs        = each.value.listener_sni_container_refs
  insert_headers            = each.value.listener_insert_headers
  allowed_cidrs             = each.value.listener_allowed_cidrs
  loadbalancer_id           = openstack_lb_loadbalancer_v2.loadbalancer.id
  default_pool_id           = openstack_lb_pool_v2.lb_pool[each.key].id
  admin_state_up            = "true"
}

#########################
### Create monitor(s) ###
#########################
resource "openstack_lb_monitor_v2" "lb_monitor" {
  for_each = local.listeners

  pool_id = openstack_lb_pool_v2.lb_pool[each.key].id

  name             = each.value.monitor_name != null ? each.value.monitor_name : format("%s-%s-%s", var.lb_name, "listener", each.key)
  type             = each.value.monitor_type
  delay            = each.value.monitor_delay
  timeout          = each.value.monitor_timeout
  max_retries      = each.value.monitor_max_retries
  max_retries_down = each.value.monitor_max_retries_down
  url_path         = each.value.monitor_url_path
  http_method      = each.value.monitor_http_method
  expected_codes   = each.value.monitor_expected_codes
  admin_state_up   = true
}

################################
### Add member(s) to pool(s) ###
#################################
resource "openstack_lb_members_v2" "members" {
  for_each = local.listeners

  pool_id = openstack_lb_pool_v2.lb_pool[each.key].id

  dynamic "member" {
    # If member_name is specified, it creates a map name: ip, otherwise ip: ip
    for_each = contains(keys(each.value), "member_name") ? zipmap(each.value.member_name, each.value.member_address) : zipmap(each.value.member_address, each.value.member_address)
    content {
      name          = member.key
      address       = member.value
      subnet_id     = each.value.member_subnet_id
      protocol_port = each.value.member_port
    }
  }
}
