###############################################
# Example: Basic HTTP Load Balancer
#
# This example creates the following topology:
#
#  - 1 Load Balancer
#  - 1 Listener:
#      - my_http -> port 80 -> my_pool
#
#  - 1 Pool (HTTP) with health monitor:
#      - my_pool
#        - HTTP monitor
#        - Backend members: http instances
#
# Traffic flow:
#  VIP:80 -> my_http listener -> my_pool pool -> http instances
###############################################

#############
### Image ###
#############
data "openstack_images_image_v2" "image" {
  most_recent = true
  tag         = "ubuntu-jammy"
}

###################
### Instance(s) ###
###################
resource "openstack_compute_instance_v2" "http" {
  count = 2

  name            = format("test-basic-http-%02d", count.index + 1)
  image_id        = data.openstack_images_image_v2.image.id
  flavor_name     = var.flavor_name
  key_pair        = var.keypair_name
  security_groups = [var.secgroup_name]

  network {
    uuid = var.network_id
  }

  # Cloud-init user_data: install Apache and expose basic info on "/"
  user_data = <<-EOF
#cloud-config
runcmd:
  - apt update
  - apt -y install apache2
  - systemctl enable apache2
  - systemctl start apache2
  - echo "$(hostname; echo ; ip a)" > /var/www/html/index.html
EOF
}

#####################
### Basic http LB ###
#####################
module "openstack-lb" {
  source = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"

  # Logical name for the load balancer
  lb_name = "example-basic-http"

  # Subnet where the LB VIP will be allocated
  lb_vip_subnet_id = var.subnet_id

  #################
  # HTTP listener #
  #################
  listeners = {
    # The map key "my_http" is the listener key
    my_http = {
      protocol      = "HTTP"
      protocol_port = 80

      # default_pool_key MUST match a pool key from the "pools" map below
      # Traffic arriving on this listener will be sent to pool "my_pool"
      default_pool_key = "my_pool"
    }
  }

  ############
  # One Pool #
  ############
  pools = {
    # The map key "my_pool" is the pool key
    my_pool = {
      protocol = "HTTP"
      monitor  = { type = "HTTP", delay = 5, timeout = 3, max_retries = 3 }

      # Build members map. One entry per instance
      # Example:
      # {
      #   "test-basic-http-01" = { address = "10.x.x.x", protocol_port = 80 }
      #   "test-basic-http-02" = { address = "10.x.x.y", protocol_port = 80 }
      # }
      #
      # - key:   instance name
      # - value: backend address and port
      members = {
        for inst in openstack_compute_instance_v2.http :
        inst.name => {
          address       = inst.network[0].fixed_ip_v4
          protocol_port = 80
        }
      }
    }
  }
}

#####################
### LB VIP Output ###
#####################
output "vip_address" {
  description = "Allocated VIP address"
  value       = module.openstack-lb.vip_address
}
