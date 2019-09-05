# terraform-openstack-loadbalancer

Terraform module to create Load Balancer on OpenStack.

## Terraform versions

It requires terraform version 0.12 or later.

## Inputs

| Name | Description | Type | Default | Required |
|:-----|:------------|:----:|:-------:|:--------:|
|name  | Name to prefix all resources created on OpenStack | string | - | **yes** |
|lb_description  | Human-readable description for the Loadbalancer | string | `-` | no |
|lb_vip_subnet_id  | The network on which to allocate the Loadbalancer's address | string | - | **yes** |
|lb_security_group_ids  | A list of security group IDs to apply to the loadbalancer | list(string) | `[]` | no |
|listener_protocol  | The protocol - can either be TCP, HTTP, HTTPS or TERMINATED_HTTPS | string | `HTTP` | no |
|listener_protocol_port  | The port on which to listen for client traffic | string | `80` | no |
|listener_connection_limit  | The maximum number of connections allowed for the Listener | string | `-1` | no |
|lb_pool_method  | The load balancing algorithm to distribute traffic to the pool's members. Must be one of ROUND_ROBIN, LEAST_CONNECTIONS, or SOURCE_IP | string | `ROUND_ROBIN` | no |
|lb_pool_protocol  | The protocol - can either be TCP, HTTP, HTTPS or PROXY | string | `HTTP` | no |
|monitor_url_path  | Required for HTTP(S) types. URI path that will be accessed if monitor type is HTTP or HTTPS | string | `/` | no |
|monitor_expected_codes  | Required for HTTP(S) types. Expected HTTP codes for a passing HTTP(S) monitor. You can either specify a single status like 200, or a range like 200-202 | string | `200` | no |
|monitor_delay  | The time, in seconds, between sending probes to members | string | `20` | no |
|monitor_timeout  | Maximum number of seconds for a monitor to wait for a ping reply before it times out | string | `10` | no |
|monitor_max_retries  | Number of permissible ping failures before changing the member's status to INACTIVE. Must be a number between 1 and 10 | string | `5` | no |
|member_port  | The port on which to listen for client traffic | string | `80` | no |
|member_address  | The IP addresses of the member to receive traffic from the load balancer | list(string) | - | **yes** |
|member_subnet_id  | The subnet in which to access the member | string | `-` | no |
|certificate  | The certificate data to be stored. (file_name) | string | `-` | no |
|private_key  | The private key data to be stored. (file_name) | string | `-` | no |
|certificate_intermediate  | The intermediate certificate data to be stored. (file_name) | string | `-` | no |


## Outputs

| Name | Description |
|:-----|:------------|
| loadbalancer_id | Load balancer ID |
| loadbalancer_ip | Load balancer IP address |
| loadbalancer_vip_port_id | The Port ID of the Load Balancer IP |
| loadbalancer_name | Human-readable name for the Loadbalancer |
| listener_id | Listener ID |
| listener_protocol | Listener protocol |
| listener_protocol_port | The port on which to listen for client traffic |
| lb_pool_id | Load balancer pool ID |
| member_port | The port on which to listen for client traffic |
| member_address | The IP address of the member to receive traffic from the load balancer |


## Usage example

Create a http load balancer:

```hcl
### Load balancer
module "openstack-lb" {
  source            = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"
  name              = "test-http"
  lb_description    = "Test load balancer using terraform module"
  lb_vip_subnet_id  = var.public_subnet_id
  member_address    = openstack_compute_instance_v2.myinstances[*].access_ip_v4
  member_subnet_id  = var.private_subnet_id
}
```

Create a https balance with certificate on backend servers:

```hcl
### Load balancer
module "openstack-lb" {
  source            = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"
  name              = "test-https-backend"
  lb_description    = "Test load balancer using terraform module"
  lb_vip_subnet_id  = var.public_subnet_id

  listener_protocol      = "HTTPS"
  listener_protocol_port = "443"

  lb_pool_protocol  = "HTTPS"
  member_port       = "443"
  member_address    = openstack_compute_instance_v2.myinstances[*].access_ip_v4
  member_subnet_id  = var.private_subnet_id
}
```

Create a https balance with certificate stored on the load balancer:

```hcl
### Load balancer
module "openstack-lb" {
  source            = "git::https://github.com/thobiast/terraform-openstack-loadbalancer.git"
  name              = "test-https-balance"
  lb_description    = "Test load balancer using terraform module"
  lb_vip_subnet_id  = var.public_subnet_id

  listener_protocol      = "TERMINATED_HTTPS"
  listener_protocol_port = "443"
  certificate            = "my_certificate_file.crt"
  private_key            = "my_private_key_file.key"

  lb_pool_protocol  = "HTTP"
  member_port       = "80"
  member_address    = openstack_compute_instance_v2.myinstances[*].access_ip_v4
  member_subnet_id  = var.private_subnet_id
}
```
