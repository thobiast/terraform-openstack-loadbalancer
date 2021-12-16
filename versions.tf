terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = ">= 0.13"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.43"
    }
  }
}
