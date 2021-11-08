output "customer_subnet" {
  value = data.openstack_networking_subnet_v2.customer_network_subnet
}

output "ip" {
  value = module.openstack-lb.loadbalancer_ip
}

output "instance_ip" {
  value = data.openstack_compute_instance_v2.instance.network.0
}

output "id" {
  value = module.openstack-lb.loadbalancer_id
}

output "instance" {
  value = data.openstack_compute_instance_v2.instance
}

output "port" {
  value = module.openstack-lb.loadbalancer_vip_port_id
}
