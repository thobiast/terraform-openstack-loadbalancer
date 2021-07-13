output "loadbalancer_id" {
  description = "Load balancer ID"
  value       = openstack_lb_loadbalancer_v2.loadbalancer.id
}

output "loadbalancer_ip" {
  description = "Load balancer IP address"
  value       = openstack_lb_loadbalancer_v2.loadbalancer.vip_address
}

output "loadbalancer_vip_port_id" {
  description = "The Port ID of the Load Balancer IP"
  value       = openstack_lb_loadbalancer_v2.loadbalancer.vip_port_id
}

output "loadbalancer_name" {
  description = "Human-readable name for the Loadbalancer"
  value       = openstack_lb_loadbalancer_v2.loadbalancer.name
}

output "listeners" {
  description = "Listener information"
  value = {
    for i in openstack_lb_listener_v2.listener :
    i.name => {
      "listener_id"   = i.id
      "protocol"      = i.protocol
      "protocol_port" = i.protocol_port
    }
  }
}

output "lb_pools" {
  description = "Load balancer pool information"
  value = {
    for i in openstack_lb_pool_v2.lb_pool :
    i.name => {
      "pool_id"       = i.id
      "pool_protocol" = i.protocol
      "lb_method"     = i.lb_method
    }
  }
}

output "monitor_http" {
  description = "Load balancer HTTP like monitor information"
  value = {
    for i in openstack_lb_monitor_v2.lb_monitor :
    i.name => {
      "id"             = i.id
      "pool_id"        = i.pool_id
      "type"           = i.type
      "delay"          = i.delay
      "timeout"        = i.timeout
      "max_retries"    = i.max_retries
      "expected_codes" = i.expected_codes
      "url_path"       = i.url_path
    }
  }
}

output "monitor_tcp" {
  description = "Load balancer TCP monitor information"
  value = {
    for i in openstack_lb_monitor_v2.lb_monitor_tcp :
    i.name => {
      "id"          = i.id
      "pool_id"     = i.pool_id
      "type"        = i.type
      "delay"       = i.delay
      "timeout"     = i.timeout
      "max_retries" = i.max_retries
    }
  }
}

output "members" {
  description = "Member(s) information"
  value = {
    for i in openstack_lb_members_v2.members :
    i.pool_id => {
      "id"    = [for k in i.member : k["id"]]
      "names" = [for k in i.member : k["name"]]
      "ips"   = [for k in i.member : k["address"]]
      "port"  = join(",", distinct([for k in i.member : k["protocol_port"]]))
    }
  }
}
