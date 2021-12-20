# terraform-openstack-loadbalancer

![Terraform Build](https://github.com/thobiast/terraform-openstack-loadbalancer/workflows/Terraform/badge.svg)
[![GitHub License](https://img.shields.io/github/license/thobiast/terraform-openstack-loadbalancer)](https://github.com/thobiast/terraform-openstack-loadbalancer/blob/master/LICENSE)

Terraform module to create Load Balancer on OpenStack.

## Terraform versions

It requires Terraform version 0.13 or later.

For Terraform v0.11 and v0.12 use version v0.1.\* of this module.

Version 2.0 supports multiple listeners and Breaks Backwards Compatibility. If you are using the previous version, please use the *"version = 1.0.0"*.

## Inputs

| Name | Description | Type | Default | Required |
|:-----|:------------|:----:|:-------:|:--------:|
|lb_name  | Human-readable name for the Loadbalancer | string | - | **yes** |
|lb_description  | Human-readable description for the Loadbalancer | string | `-` | no |
|lb_vip_subnet_id  | The network's subnet on which to allocate the Loadbalancer's address | string | `null` | no |
|lb_vip_network_id  | The network on which to allocate the Loadbalancer's address | string | `null` | no |
|lb_vip_port_id  | The network's port on which want to connect the loadbalancer | string | `null` | no |
|lb_vip_address  | The ip address of the load balancer | string | `null` | no |
|lb_loadbalancer_provider  | The name of the provider | string | `null` | no |
|lb_availability_zone  | The availability zone of the Loadbalancer | string | `null` | no |
|lb_security_group_ids  | A list of security group IDs to apply to the loadbalancer | list(string) | `[]` | no |
|lb_flavor_id  | Loadbalancer flavor (HA, stand-alone) | string | `null` | no |
|tags  | A list of strings to add to the load balancer | list(string) | `[]` | no |
|listeners  | Map with Listener(s) to create | map(object) | - | **yes** |


**Listener map structure**

| Name | Description | Type | Default | Required |
|:-----|:------------|:----:|:-------:|:--------:|
| listener_name                     | Human-readable name for the Listener | optional(string) | - | no |
| listener_description              | Human-readable description for the Listener | optional(string) | - | no |
| listener_protocol                 | The protocol - can either be TCP,HTTP,HTTPS,TERMINATED_HTTPS,UDP,SCTP | string | - | **yes** |
| listener_protocol_port            | The port on which to listen for client traffic | string | - | **yes** |
| listener_connection_limit         | The maximum number of connections allowed for the Listener | optional(string) | - | no |
| listener_timeout_client_data      | The client inactivity timeout in milliseconds | optional(string) | | no |
| listener_timeout_member_connect   | The member connection timeout in milliseconds | optional(string) | - | no |
| listener_timeout_member_data      | The member inactivity timeout in milliseconds | optional(string) | - | no |
| listener_timeout_tcp_inspect      | The time in milliseconds, to wait for additional TCP packets for content inspection | optional(string) | - | no |
| listener_tls_container_ref        | A reference to a Barbican Secrets container which stores TLS information. This is required if the protocol is TERMINATED_HTTPS | optional(string) | - | no |
| listener_sni_container_refs       | A list of references to Barbican Secrets containers which store SNI information | optional(list(string)) | - | no |
| listener_insert_headers           | The list of key value pairs representing headers to insert into the request before it is sent to the backend members | optional(map(string)) | - | no |
| listener_allowed_cidrs            | A list of CIDR blocks that are permitted to connect to this listener, denying all other source addresses. If not present, defaults to allow all | optional(list(string)) | - | no |
| pool_name                         | Human-readable name for the pool | optional(string) | - | no |
| pool_description                  | Human-readable description for the pool | optional(string) | - | no |
| pool_protocol                     | The protocol - can either be TCP,HTTP,HTTPS,PROXY,PROXYV2,UDP,SCTP | string | - | **yes** |
| pool_method                       | The load balancing algorithm to distribute traffic to the pool's members. Must be one of ROUND_ROBIN,LEAST_CONNECTIONS,SOURCE_IP,SOURCE_IP_PORT | optional(string) | `ROUND_ROBIN` | no |
| pool_sess_persistence_type        | The type of persistence mode. The current specification supports SOURCE_IP,HTTP_COOKIE,APP_COOKIE | optional(string) | - | no |
| pool_sess_persistence_cookie_name | The name of the cookie if persistence mode is set appropriately. Required if type = APP_COOKIE | optional(string) | - | no |
| monitor_name                      | The Name of the Monitor | optional(string) | - | no |
| monitor_type                      | The health monitor type. Supported values PING,HTTP,TCP,HTTPS,TLS-HELLO,UDP-CONNECT,SCTP | string | - | **yes** |
| monitor_delay                     | The time, in seconds, between sending probes to members | optional(string) | `10`| no |
| monitor_timeout                   | Maximum number of seconds for a monitor to wait for a ping reply before it times out. The value must be less than the delay value | optional(string) | `5` | no |
| monitor_max_retries               | Number of permissible ping failures before changing the member's status to INACTIVE. Must be a number between 1 and 10 | optional(string) | `3` | no |
| monitor_max_retries_down          | Number of permissible ping failures befor changing the member's status to ERROR. Must be a number between 1 and 10 | optional(string) | - | no |
| monitor_url_path                  | Required for HTTP(S) types. URI path that will be accessed if monitor type is HTTP or HTTPS | optional(string) | - | no |
| monitor_http_method               | Required for HTTP(S) types. The HTTP method used for requests by the monitor. If this attribute is not specified, it defaults to "GET" | optional(string) | - | no |
| monitor_expected_codes            | Required for HTTP(S) types. Expected HTTP codes for a passing HTTP(S) monitor. You can either specify a single status like "200", or a range like "200-202" | optional(string) | - | no |
| member_address                    | The IP address of the members to receive traffic from the load balancer | optional(list(string)) | - | no |
| member_name                       | Human-readable name for the member | optional(list(string)) | - | no |
| member_subnet_id                  | The subnet in which to access the member | optional(string) | - | no |
| member_port                       | The port on which to listen for client traffic | optional(string) | - | no |


## Outputs

| Name | Description |
|:-----|:------------|
| loadbalancer_id | Load balancer ID |
| loadbalancer_ip | Load balancer IP address |
| loadbalancer_vip_port_id | The Port ID of the Load Balancer IP |
| loadbalancer_name | Human-readable name for the Loadbalancer |
| loadbalancer | Loadbalancer information |
| listeners | Listeners information |
| pools | Load balancer pool information |
| monitor | Load balancer monitor information |
| members | Member(s) information |


## Usage example

Create a load balancer with one listener HTTP:

```hcl
### Load balancer
module "openstack-lb" {
  source                = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"
  lb_name               = "test-http"
  lb_description        = "Test load balancer using terraform module"
  lb_security_group_ids = [openstack_networking_secgroup_v2.my_lb.id]
  lb_vip_subnet_id      = var.public_subnet_id
  listeners = {
    http = {
      listener_name          = "My Listener HTTP"
      listener_protocol      = "HTTP"
      listener_protocol_port = 80
      pool_protocol          = "HTTP"
      monitor_type           = "HTTP"
      member_address         = openstack_compute_instance_v2.http[*].access_ip_v4
      member_name            = openstack_compute_instance_v2.http[*].name
      member_port            = 80
    }
  }
}
```

Create a load balancer with one listener HTTP and other TCP.

```hcl
### Load balancer
module "openstack-lb" {
  source                = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"
  lb_name               = "Test load balancer with multiple listeners"
  lb_description        = "Test load balancer using terraform module"
  lb_security_group_ids = [openstack_networking_secgroup_v2.my_lb.id]
  lb_vip_subnet_id      = module.openstack-env.public_subnet_id
  listeners = {
    http = {
      listener_name                     = "My Listener HTTP"
      listener_protocol                 = "HTTP"
      listener_protocol_port            = 80
      listener_insert_headers           = { X-Forwarded-For = "true" }
      pool_protocol                     = "HTTP"
      pool_method                       = "SOURCE_IP"
      pool_sess_persistence_type        = "APP_COOKIE"
      pool_sess_persistence_cookie_name = "testCookie"
      monitor_type                      = "HTTP"
      monitor_delay                     = 7
      monitor_timeout                   = 5
      monitor_max_retries               = 3
      monitor_url_path                  = "/healthcheck"
      monitor_expected_codes            = "200-201"
      member_address                    = openstack_compute_instance_v2.http[*].access_ip_v4
      member_name                       = openstack_compute_instance_v2.http[*].name
      member_port                       = 80
    },
    tcp = {
      listener_name          = "my listener TCP"
      listener_protocol      = "TCP"
      listener_protocol_port = 22
      listener_allowed_cidrs = ["192.168.2.0/24"]
      pool_name              = "My TCP pool"
      pool_protocol          = "TCP"
      pool_method            = "SOURCE_IP"
      monitor_type           = "TCP"
      member_address         = openstack_compute_instance_v2.ssh[*].access_ip_v4
      member_name            = openstack_compute_instance_v2.ssh[*].name
      member_port            = 22
    }
  }
}
```

Create a load balancer with one listener HTTP and one HTTPS with TLS certificate stored on the load balancer.

```hcl
### Load balancer
module "openstack-lb" {
  source                = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"
  lb_name               = "Test load balancer with multiple listeners"
  lb_description        = "Test load balancer using terraform module"
  lb_security_group_ids = [openstack_networking_secgroup_v2.my_lb.id]
  lb_vip_subnet_id      = module.openstack-env.public_subnet_id
  listeners = {
    http = {
      listener_name          = "My Listener HTTP"
      listener_protocol      = "HTTP"
      listener_protocol_port = 80
      pool_protocol          = "HTTP"
      monitor_type           = "HTTP"
      member_address         = openstack_compute_instance_v2.http[*].access_ip_v4
      member_name            = openstack_compute_instance_v2.http[*].name
      member_port            = 80
    },
    https = {
      listener_name              = "My Listener HTTPS"
      listener_protocol          = "TERMINATED_HTTPS"
      listener_protocol_port     = 443
      listener_tls_container_ref = openstack_keymanager_container_v1.tls_1.container_ref
      pool_name                  = "Pool HTTP"
      pool_protocol              = "HTTP"
      monitor_type               = "HTTP"
      member_address             = openstack_compute_instance_v2.http[*].access_ip_v4
      member_name                = openstack_compute_instance_v2.http[*].name
      member_port                = 80
    }
  }
}
```
