variable "instance" {
  description = "OpenStack instance's ID to add as a member"
  type = string
}

variable "private_network" {
  description = "The OpenStack network's ID which will be used 'between' LB and member"
  type = string
}

variable "public_network" {
  description = "The OpenStack network's ID which will be used as public network for the LB"
  type = string
}
