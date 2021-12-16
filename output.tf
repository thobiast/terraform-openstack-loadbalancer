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

output "loadbalancer" {
  description = "Loadbalancer information"
  value       = openstack_lb_loadbalancer_v2.loadbalancer
}

output "listeners" {
  description = "Listeners information"
  value       = openstack_lb_listener_v2.lb_listener
}

output "pools" {
  description = "Load balancer pool information"
  value       = openstack_lb_pool_v2.lb_pool
}

output "monitor" {
  description = "Load balancer monitor information"
  value       = openstack_lb_monitor_v2.lb_monitor
}

output "members" {
  description = "Member(s) information"
  value       = openstack_lb_members_v2.members
}
