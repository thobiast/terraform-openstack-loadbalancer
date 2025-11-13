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
  flavor_id             = var.lb_flavor_id
  vip_qos_policy_id     = var.lb_vip_qos_policy_id
  tags                  = var.tags
  admin_state_up        = var.admin_state_up

  lifecycle {
    precondition {
      condition     = length(local._bad_default_pool_refs) == 0
      error_message = "listeners[*].default_pool_key must match a key in var.pools: ${join(", ", local._bad_default_pool_refs)}"
    }
    precondition {
      condition     = length(local._bad_redirect_policies) == 0
      error_message = "L7policies with action=REDIRECT_TO_POOL have invalid redirect_pool_key references: ${join(", ", local._bad_redirect_policies)}"
    }
    precondition {
      condition     = length(local._bad_listener_refs_in_policies) == 0
      error_message = "Each l7_policies[*].listener_key must match a key in var.listeners: ${join(", ", local._bad_listener_refs_in_policies)}"
    }
  }
}


######################
### Create pool(s) ###
######################
resource "openstack_lb_pool_v2" "pool" {
  for_each    = var.pools
  name        = coalesce(try(each.value.name, null), format("lb:%s pool:%s", var.lb_name, each.key))
  description = try(each.value.description, null)
  protocol    = upper(each.value.protocol)
  lb_method   = upper(each.value.lb_method)

  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id

  dynamic "persistence" {
    for_each = each.value.persistence == null ? [] : [each.value.persistence]
    content {
      type        = upper(persistence.value.type)
      cookie_name = try(persistence.value.cookie_name, null)
    }
  }
}


##################################
### Create monitor(s) per pool ###
##################################
resource "openstack_lb_monitor_v2" "monitor" {
  for_each = {
    for pool_key, pool in var.pools : pool_key => pool
    if try(pool.monitor, null) != null
  }
  name = coalesce(
    try(each.value.monitor.name, null),
    format("lb:%s pool:%s monitor", var.lb_name, each.key)
  )

  pool_id          = openstack_lb_pool_v2.pool[each.key].id
  type             = upper(each.value.monitor.type)
  delay            = each.value.monitor.delay
  timeout          = each.value.monitor.timeout
  max_retries      = each.value.monitor.max_retries
  max_retries_down = try(each.value.monitor.max_retries_down, null)
  url_path         = try(each.value.monitor.url_path, null)
  http_method      = try(each.value.monitor.http_method, null)
  http_version     = try(each.value.monitor.http_version, null)
  expected_codes   = try(each.value.monitor.expected_codes, null)
  admin_state_up   = each.value.monitor.admin_state_up
}


############################
### Add members to pools ###
############################
resource "openstack_lb_member_v2" "member" {
  for_each = local.members_by_key

  name = coalesce(try(each.value.member.name, null), each.key)

  pool_id         = openstack_lb_pool_v2.pool[each.value.pool_key].id
  address         = each.value.member.address
  protocol_port   = each.value.member.protocol_port
  subnet_id       = try(each.value.member.subnet_id, null)
  weight          = try(each.value.member.weight, null)
  monitor_port    = try(each.value.member.monitor_port, null)
  monitor_address = try(each.value.member.monitor_address, null)
  backup          = try(each.value.member.backup, null)
  tags            = try(each.value.member.tags, [])
}


#################
### Listeners ###
#################
resource "openstack_lb_listener_v2" "listener" {
  for_each = var.listeners

  name            = coalesce(try(each.value.name, null), format("lb:%s listener:%s", var.lb_name, each.key))
  description     = try(each.value.description, null)
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id
  protocol        = upper(each.value.protocol)
  protocol_port   = each.value.protocol_port
  tags            = each.value.tags
  admin_state_up  = each.value.admin_state_up

  default_pool_id = try(openstack_lb_pool_v2.pool[each.value.default_pool_key].id, null)

  insert_headers = each.value.insert_headers
  allowed_cidrs  = each.value.allowed_cidrs

  connection_limit       = try(each.value.connection_limit, null)
  timeout_client_data    = try(each.value.timeout_client_data, null)
  timeout_member_connect = try(each.value.timeout_member_connect, null)
  timeout_member_data    = try(each.value.timeout_member_data, null)
  timeout_tcp_inspect    = try(each.value.timeout_tcp_inspect, null)

  default_tls_container_ref = try(each.value.default_tls_container_ref, null)
  sni_container_refs        = try(each.value.sni_container_refs, null)
  tls_ciphers               = try(each.value.tls_ciphers, null)
  tls_versions              = try(each.value.tls_versions, null)

  client_authentication       = try(each.value.client_authentication, null)
  client_ca_tls_container_ref = try(each.value.client_ca_tls_container_ref, null)
  client_crl_container_ref    = try(each.value.client_crl_container_ref, null)
}


###################
### L7 Policies ###
###################
resource "openstack_lb_l7policy_v2" "policy" {
  for_each = local.l7policies_by_key

  name = coalesce(
    try(each.value.policy.name, null),
    format("lb:%s lsn:%s pol:%s", var.lb_name, each.value.listener_key, each.value.policy_key)
  )
  description        = try(each.value.policy.description, null)
  listener_id        = openstack_lb_listener_v2.listener[each.value.listener_key].id
  action             = upper(each.value.policy.action)
  position           = each.value.policy.position
  redirect_url       = try(each.value.policy.redirect_url, null)
  redirect_pool_id   = try(openstack_lb_pool_v2.pool[each.value.policy.redirect_pool_key].id, null)
  redirect_prefix    = try(each.value.policy.redirect_prefix, null)
  redirect_http_code = try(each.value.policy.redirect_http_code, null)
  admin_state_up     = each.value.policy.admin_state_up
}


################
### L7 Rules ###
################
resource "openstack_lb_l7rule_v2" "rule" {
  for_each = local.l7rules_by_key

  # Locate the policy resource by its composite key
  l7policy_id = openstack_lb_l7policy_v2.policy[each.value.l7policy_key].id

  type         = upper(each.value.rule.type)
  compare_type = upper(each.value.rule.compare_type)
  value        = each.value.rule.value
  key          = try(each.value.rule.key, null)
  invert       = each.value.rule.invert
}
