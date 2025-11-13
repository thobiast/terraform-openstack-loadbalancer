output "loadbalancer_id" {
  description = "Load balancer ID"
  value       = openstack_lb_loadbalancer_v2.loadbalancer.id
}
output "vip_address" {
  description = "Allocated VIP address"
  value       = openstack_lb_loadbalancer_v2.loadbalancer.vip_address
}
output "loadbalancer" {
  description = "The full OpenStack load balancer resource object"
  value       = openstack_lb_loadbalancer_v2.loadbalancer
}
output "listeners" {
  description = "A map of all created OpenStack listener resource objects"
  value       = openstack_lb_listener_v2.listener
}
output "pools" {
  description = "A map of all created OpenStack pool resource objects"
  value       = openstack_lb_pool_v2.pool
}
output "monitors" {
  description = "A map of all created OpenStack monitor resource objects"
  value       = openstack_lb_monitor_v2.monitor
}
output "members" {
  description = "A map of all created OpenStack member resource objects"
  value       = openstack_lb_member_v2.member
}
output "l7policies" {
  description = "A map of all created OpenStack L7 policy resource objects"
  value       = openstack_lb_l7policy_v2.policy
}
output "l7rules" {
  description = "A map of all created OpenStack L7 rule resource objects"
  value       = openstack_lb_l7rule_v2.rule
}
output "listener_ids_by_key" {
  description = "Map: listener key - listener ID"
  value       = { for k, v in openstack_lb_listener_v2.listener : k => v.id }
}
output "pool_ids_by_key" {
  description = "Map: pool key - pool ID"
  value       = { for k, v in openstack_lb_pool_v2.pool : k => v.id }
}
output "monitor_ids_by_pool_key" {
  description = "Map: pool key - monitor ID"
  value       = { for k, v in openstack_lb_monitor_v2.monitor : k => v.id }
}
output "member_ids" {
  description = "Map: pool/member - member ID"
  value       = { for k, v in openstack_lb_member_v2.member : k => v.id }
}
output "l7policy_ids_by_key" {
  description = "Map: listener/policy - l7policy ID"
  value       = { for k, v in openstack_lb_l7policy_v2.policy : k => v.id }
}
output "l7rule_ids_by_key" {
  description = "Map: listener/policy/rule - l7rule ID"
  value       = { for k, v in openstack_lb_l7rule_v2.rule : k => v.id }
}
