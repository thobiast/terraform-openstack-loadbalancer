output "customer_subnet" {
  value = data.openstack_networking_subnet_v2.customer_network_subnet
}

output "public_network_subnet" {
  value = data.openstack_networking_subnet_v2.public_network_subnet
}

output "ip" {
  value = module.openstack-lb.loadbalancer_ip
}

output "id" {
  value = module.openstack-lb.loadbalancer_id
}

output "port" {
  value = module.openstack-lb.loadbalancer_vip_port_id
}
