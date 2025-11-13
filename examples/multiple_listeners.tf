###############################################
# Example: Load Balancer with Two Listeners
#
# This example creates the following topology:
#
#  - 1 Load Balancer
#  - 2 Listeners:
#      - http       -> port 80   -> frontend_pool
#      - http_admin -> port 8080 -> admin_pool
#
#  - 2 Pools (HTTP), each with its own health monitor:
#      - frontend_pool
#         - HTTP monitor
#         - Backend members: frontend instances
#      - admin_pool
#         - HTTP monitor
#         - Backend members: admin instances
#
# Traffic flow:
#  VIP:80   -> http listener       -> frontend_pool -> frontend instances
#  VIP:8080 -> http_admin listener -> admin_pool    -> admin instances
###############################################

#############
### Image ###
#############
data "openstack_images_image_v2" "distro" {
  most_recent = true
  tag         = "ubuntu-jammy"
}

##############################
### Instance(s): front-end ###
##############################
resource "openstack_compute_instance_v2" "frontend" {
  count = 2

  name            = format("example-frontend-%02d", count.index + 1)
  image_id        = data.openstack_images_image_v2.distro.id
  flavor_name     = var.flavor_name
  key_pair        = var.keypair_name
  security_groups = [openstack_networking_secgroup_v2.my_lb.name]

  network {
    uuid = var.network_id
  }

  user_data = <<-EOF
#cloud-config
runcmd:
  - apt update
  - apt -y install apache2
  - systemctl enable apache2
  - systemctl start apache2
  - echo "FRONTEND - $(hostname; echo ; ip a)" > /var/www/html/index.html
EOF
}

##########################
### Instance(s): admin ###
##########################
resource "openstack_compute_instance_v2" "admin" {
  count = 2

  name            = format("example-admin-%02d", count.index + 1)
  image_id        = data.openstack_images_image_v2.distro.id
  flavor_name     = var.flavor_name
  key_pair        = var.keypair_name
  security_groups = [openstack_networking_secgroup_v2.my_lb.name]

  network {
    uuid = var.network_id
  }

  user_data = <<-EOF
#cloud-config
runcmd:
  - apt update
  - apt -y install apache2
  - systemctl enable apache2
  - systemctl start apache2
  - echo "ADMIN - $(hostname; echo ; ip a)" > /var/www/html/index.html
EOF
}

##############################
### LB: Multiple listeners ###
##############################
module "openstack-lb" {
  source = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"

  # Logical name for the load balancer
  lb_name = "example-multiple-listeners"

  # Subnet where the LB VIP will be allocated
  lb_vip_subnet_id = var.subnet_id

  #######################
  # Two HTTP listeners  #
  #######################
  listeners = {
    # The map key "http" is the listener key
    # This listener will handle user/regular traffic on port 80
    http = {
      name          = "frontend"
      protocol      = "HTTP"
      protocol_port = 80

      # default_pool_key MUST match a pool key from the "pools" map below
      # Traffic arriving on this listener will be sent to "frontend_pool"
      default_pool_key = "frontend_pool"
    }
    # The map key "http_admin" is the listener key
    # This listener will handle admin traffic on port 8080
    http_admin = {
      name          = "admin"
      protocol      = "HTTP"
      protocol_port = 8080

      # default_pool_key MUST match a pool key from the "pools" map below
      # Traffic arriving on this listener will be sent to "admin_pool"
      default_pool_key = "admin_pool"
    }
  }

  #############
  # Two pools #
  #############
  pools = {
    # The map key "frontend_pool" is the pool key
    # This pool receives traffic from listener "http" (port 80)
    frontend_pool = {
      protocol = "HTTP"
      monitor  = { type = "HTTP", delay = 5, timeout = 3, max_retries = 3 }
      members = {
        # One member per frontend instance
        for inst in openstack_compute_instance_v2.frontend :
        inst.name => {
          address       = inst.network[0].fixed_ip_v4
          protocol_port = 80
        }
      }
    }
    # The map key "admin_pool" is the pool key
    # This pool receives traffic from listener "http_admin" (port 8080)
    admin_pool = {
      protocol = "HTTP"
      monitor  = { type = "HTTP", delay = 5, timeout = 3, max_retries = 3 }
      members = {
        # One member per admin instance
        for inst in openstack_compute_instance_v2.admin :
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
