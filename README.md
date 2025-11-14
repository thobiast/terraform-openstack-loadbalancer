# terraform-openstack-loadbalancer

![Terraform Build](https://github.com/thobiast/terraform-openstack-loadbalancer/workflows/Terraform/badge.svg)
[![GitHub License](https://img.shields.io/github/license/thobiast/terraform-openstack-loadbalancer)](https://github.com/thobiast/terraform-openstack-loadbalancer/blob/master/LICENSE)

Terraform module to create an OpenStack Load Balancer, including listeners, pools, members, health monitors, and L7 policies/rules.

This module is designed to be flexible. It accepts structured maps for each resource type, enabling you to define a complete load balancer topology.

## Module versions

- **For Terraform v0.11 and v0.12**, use module version **v0.1.\***.
- **Version 2.0+** introduces multiple listeners, more configuration options, and L7 policy support.
  **This release is not backward compatible.**

If you are using the older module schema, pin your version to:

```hcl
version = "1.0.0"
```

## Usage Example

#### Basic HTTP load balancer

```hcl
#####################
### Basic HTTP LB ###
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

      # The "members" block dynamically adds all backend servers to this pool
      #
      #   openstack_compute_instance_v2.http[*]
      #
      # Each instance creates one pool member:
      #   - key           = instance name
      #   - value         = instance IP
	  #   - protocol_port = member port
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
```

#### Load balancer with L7 Policy

```hcl
#########################
### LB with L7 Policy ###
#########################
module "openstack-lb" {
  source = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"

  lb_name          = "example-l7-policy"
  lb_vip_subnet_id = var.subnet_id

  #################
  # HTTP listener #
  #################
  listeners = {
    # The map key "my_http_listener" is the listener key
    # This same key will be used under `l7policies` to attach L7 policies
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
    # This map key MUST match the listener key under "listeners" map
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
```

You can find additional and more complete examples in the [`examples/`](./examples/) directory.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_openstack"></a> [openstack](#requirement\_openstack) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_openstack"></a> [openstack](#provider\_openstack) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [openstack_lb_l7policy_v2.policy](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/lb_l7policy_v2) | resource |
| [openstack_lb_l7rule_v2.rule](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/lb_l7rule_v2) | resource |
| [openstack_lb_listener_v2.listener](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/lb_listener_v2) | resource |
| [openstack_lb_loadbalancer_v2.loadbalancer](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/lb_loadbalancer_v2) | resource |
| [openstack_lb_member_v2.member](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/lb_member_v2) | resource |
| [openstack_lb_monitor_v2.monitor](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/lb_monitor_v2) | resource |
| [openstack_lb_pool_v2.pool](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/lb_pool_v2) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_state_up"></a> [admin\_state\_up](#input\_admin\_state\_up) | Load balancer admin state | `bool` | `true` | no |
| <a name="input_l7policies"></a> [l7policies](#input\_l7policies) | Map of listener-key => map of L7 policies. Policies can redirect to URL or to a pool (by pool key).<br/>- The listener\_key must match a key from var.listeners map.<br/>- The policy\_key is a logical identifier for the policy (e.g., redirect-rule).<br/>- redirect\_pool\_key (optional) must reference a valid key from var.pools map.<br/>- Each policy can contain a nested map of rules, where each key is a logical identifier for the rule. | <pre>map(map(object({<br/>    name               = optional(string)<br/>    description        = optional(string)<br/>    action             = string<br/>    position           = number<br/>    redirect_url       = optional(string)<br/>    redirect_pool_key  = optional(string)<br/>    redirect_prefix    = optional(string)<br/>    redirect_http_code = optional(number)<br/>    admin_state_up     = optional(bool, true)<br/><br/>    rules = optional(map(object({<br/>      type           = string<br/>      compare_type   = string<br/>      value          = string<br/>      key            = optional(string)<br/>      invert         = optional(bool, false)<br/>      admin_state_up = optional(bool, true)<br/>    })), {})<br/>  })))</pre> | `{}` | no |
| <a name="input_lb_availability_zone"></a> [lb\_availability\_zone](#input\_lb\_availability\_zone) | The availability zone of the load balancer | `string` | `null` | no |
| <a name="input_lb_description"></a> [lb\_description](#input\_lb\_description) | Human-readable description for the load balancer | `string` | `""` | no |
| <a name="input_lb_flavor_id"></a> [lb\_flavor\_id](#input\_lb\_flavor\_id) | Load balancer flavor (HA, stand-alone) | `string` | `null` | no |
| <a name="input_lb_loadbalancer_provider"></a> [lb\_loadbalancer\_provider](#input\_lb\_loadbalancer\_provider) | The Octavia provider driver name | `string` | `null` | no |
| <a name="input_lb_name"></a> [lb\_name](#input\_lb\_name) | Human-readable name for the load balancer | `string` | n/a | yes |
| <a name="input_lb_vip_address"></a> [lb\_vip\_address](#input\_lb\_vip\_address) | The fixed VIP IP address of the load balancer | `string` | `null` | no |
| <a name="input_lb_vip_network_id"></a> [lb\_vip\_network\_id](#input\_lb\_vip\_network\_id) | The network on which to allocate the load balancer's address | `string` | `null` | no |
| <a name="input_lb_vip_port_id"></a> [lb\_vip\_port\_id](#input\_lb\_vip\_port\_id) | The network's port on which want to connect the loadbalancer | `string` | `null` | no |
| <a name="input_lb_vip_qos_policy_id"></a> [lb\_vip\_qos\_policy\_id](#input\_lb\_vip\_qos\_policy\_id) | The ID of the QoS Policy which will be applied to the VIP port | `string` | `null` | no |
| <a name="input_lb_vip_subnet_id"></a> [lb\_vip\_subnet\_id](#input\_lb\_vip\_subnet\_id) | The network's subnet on which to allocate the load balancer's address | `string` | `null` | no |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | Map of listeners to create, keyed by a logical listener name<br/>- default\_pool\_key (optional) must reference a key in var.pools map | <pre>map(object({<br/>    name                        = optional(string)<br/>    description                 = optional(string)<br/>    protocol                    = string<br/>    protocol_port               = number<br/>    connection_limit            = optional(number)<br/>    timeout_client_data         = optional(number)<br/>    timeout_member_connect      = optional(number)<br/>    timeout_member_data         = optional(number)<br/>    timeout_tcp_inspect         = optional(number)<br/>    default_tls_container_ref   = optional(string)<br/>    sni_container_refs          = optional(list(string), [])<br/>    insert_headers              = optional(map(string), {})<br/>    allowed_cidrs               = optional(list(string), [])<br/>    client_authentication       = optional(string)<br/>    client_ca_tls_container_ref = optional(string)<br/>    client_crl_container_ref    = optional(string)<br/>    tls_ciphers                 = optional(string)<br/>    tls_versions                = optional(list(string), [])<br/>    tags                        = optional(list(string), [])<br/>    default_pool_key            = optional(string)<br/>    admin_state_up              = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_pools"></a> [pools](#input\_pools) | Map of pools keyed where each key represents a unique pool name<br/>- Each pool may define session\_persistence, an optional monitor, and a map of members.<br/>- The members map keys are logical identifiers for each member. | <pre>map(object({<br/>    name        = optional(string)<br/>    description = optional(string)<br/>    protocol    = string<br/>    lb_method   = optional(string, "ROUND_ROBIN")<br/><br/>    persistence = optional(object({<br/>      type        = string<br/>      cookie_name = optional(string)<br/>    }))<br/><br/>    monitor = optional(object({<br/>      name             = optional(string)<br/>      type             = string<br/>      delay            = number<br/>      timeout          = number<br/>      max_retries      = number<br/>      max_retries_down = optional(number)<br/>      url_path         = optional(string)<br/>      http_method      = optional(string)<br/>      http_version     = optional(string)<br/>      expected_codes   = optional(string)<br/>      admin_state_up   = optional(bool, true)<br/>    }))<br/><br/>    members = optional(map(object({<br/>      name            = optional(string)<br/>      address         = string<br/>      protocol_port   = number<br/>      subnet_id       = optional(string)<br/>      weight          = optional(number)<br/>      monitor_port    = optional(number)<br/>      monitor_address = optional(string)<br/>      backup          = optional(bool)<br/>      tags            = optional(list(string), [])<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A list of strings to add to the load balancer | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_l7policies"></a> [l7policies](#output\_l7policies) | A map of all created OpenStack L7 policy resource objects |
| <a name="output_l7policy_ids_by_key"></a> [l7policy\_ids\_by\_key](#output\_l7policy\_ids\_by\_key) | Map: listener/policy - l7policy ID |
| <a name="output_l7rule_ids_by_key"></a> [l7rule\_ids\_by\_key](#output\_l7rule\_ids\_by\_key) | Map: listener/policy/rule - l7rule ID |
| <a name="output_l7rules"></a> [l7rules](#output\_l7rules) | A map of all created OpenStack L7 rule resource objects |
| <a name="output_listener_ids_by_key"></a> [listener\_ids\_by\_key](#output\_listener\_ids\_by\_key) | Map: listener key - listener ID |
| <a name="output_listeners"></a> [listeners](#output\_listeners) | A map of all created OpenStack listener resource objects |
| <a name="output_loadbalancer"></a> [loadbalancer](#output\_loadbalancer) | The full OpenStack load balancer resource object |
| <a name="output_loadbalancer_id"></a> [loadbalancer\_id](#output\_loadbalancer\_id) | Load balancer ID |
| <a name="output_member_ids"></a> [member\_ids](#output\_member\_ids) | Map: pool/member - member ID |
| <a name="output_members"></a> [members](#output\_members) | A map of all created OpenStack member resource objects |
| <a name="output_monitor_ids_by_pool_key"></a> [monitor\_ids\_by\_pool\_key](#output\_monitor\_ids\_by\_pool\_key) | Map: pool key - monitor ID |
| <a name="output_monitors"></a> [monitors](#output\_monitors) | A map of all created OpenStack monitor resource objects |
| <a name="output_pool_ids_by_key"></a> [pool\_ids\_by\_key](#output\_pool\_ids\_by\_key) | Map: pool key - pool ID |
| <a name="output_pools"></a> [pools](#output\_pools) | A map of all created OpenStack pool resource objects |
| <a name="output_vip_address"></a> [vip\_address](#output\_vip\_address) | Allocated VIP address |
<!-- END_TF_DOCS -->
