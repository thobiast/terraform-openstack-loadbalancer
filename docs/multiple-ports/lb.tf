# get member (instance)
data "openstack_compute_instance_v2" "instance" {
  id = var.instance
}

# get network between lb and member
data "openstack_networking_subnet_v2" "customer_network_subnet" {
  name = var.private_network
}

# create loadbalancer
module "openstack-lb" {
  depends_on = [
    data.openstack_networking_subnet_v2.customer_network_subnet
  ]

  source = "../../"

  name                  = "test-lb-multi"
  lb_description        = "Test load balancer with multiple listeners"
  lb_security_group_ids = []
  lb_vip_subnet_id      = data.openstack_networking_subnet_v2.customer_network_subnet.id
  listeners = {
    https_lb1 = {
      listener_protocol      = "TCP"
      listener_protocol_port = 443
      lb_pool_protocol       = "TCP"
      member_address         = tolist([
        data.openstack_compute_instance_v2.instance.network.0.fixed_ip_v4
      ])
      member_subnet_id       = data.openstack_networking_subnet_v2.customer_network_subnet.id
    },
    http_lb1 = {
      listener_protocol      = "TCP"
      listener_protocol_port = "80"
      lb_pool_protocol       = "TCP"
      member_address         = tolist([
        data.openstack_compute_instance_v2.instance.network.0.fixed_ip_v4
      ])
      member_subnet_id       = data.openstack_networking_subnet_v2.customer_network_subnet.id
    },
  }
}
