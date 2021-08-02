terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.31"
    }
  }
  required_version = ">= 0.13"
}

provider "openstack" {
  insecure    = false
  use_octavia = true
}
