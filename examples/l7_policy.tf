##############################################################
# Example: Load Balancer with L7 Policy (Redirect to Pool)
#
# This example creates the following topology:
#
#   - 1 Load Balancer
#   - 1 HTTP listener on port 80
#   - 2 backend pools:
#       - app_default -> frontend instances
#       - app_admin   -> admin instances
#       (each pool includes an HTTP health monitor)
#
#   - 1 L7 policy applied to the listener:
#       - Requests with PATH starting with "/admin"
#         are redirected to pool "app_admin".
#       - All other requests go to pool "app_default".
#
# Traffic flow:
#   curl http://<VIP>/          -> app_default pool
#   curl http://<VIP>/admin/... -> app_admin pool
##############################################################

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

  name            = format("example-l7-frontend-%02d", count.index + 1)
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

  name            = format("example-l7-admin-%02d", count.index + 1)
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
  - mkdir /var/www/html/admin
  - echo "ADMIN - $(hostname; echo ; ip a)" > /var/www/html/admin/index.html
EOF
}

####################
### LB L7 Policy ###
####################
module "openstack-lb" {
  source = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"

  lb_name          = "example-l7-policy"
  lb_vip_subnet_id = var.subnet_id

  #################
  # HTTP listener #
  #################
  listeners = {
    # The map key "my_http_listener" is the listener key
    # This same key will be used under "l7policies" map to attach L7 policies
    my_http_listener = {
      protocol      = "HTTP"
      protocol_port = 80
      # Must match a pool key from the "pools" map below.
      default_pool_key = "app_default"
    }
  }

  ###############################
  # Two pools (default + admin) #
  ###############################
  pools = {
    # The map key "app_default" is the pool key
    # This is the default pool for normal traffic (non-/admin)
    app_default = {
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
    # The map key "app_admin" is the pool key
    # This pool only receives traffic that matches the L7 /admin rule
    app_admin = {
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

  ################################################################
  # L7 Policy: redirect /admin* to app_admin pool                #
  # Example: curl http://<vip>/admin/   # goes to app_admin pool #
  ################################################################
  l7policies = {
    # This map key MUST match the listener key in the "listeners" map
    # In this case "my_http_listener"
    my_http_listener = {
      path_to_admin = {
        action   = "REDIRECT_TO_POOL"
        position = 1
        # Redirect to the pool whose key is "app_admin" in "pools" map
        redirect_pool_key = "app_admin"
        rules = {
          path_admin = { type = "PATH", compare_type = "STARTS_WITH", value = "/admin" }
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
