variable "instance" {
  description = "OpenStack instance's ID to add as a member"
  type        = string
}

variable "private_network" {
  description = "The OpenStack network's ID which will be used 'between' LB and member"
  type        = string
}

variable "flavor" {
  description = "The OpenStack loadbalancer flavor (octavia: HA or stand-alone)"
  default     = null
  type        = string
}
