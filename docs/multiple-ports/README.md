# multiple ports

This example setup is for a OpenStack LBaaS (Octavia) with multiple ports.

Applying the plan will create:

 - a loadbalancer with pools for ports 80 and 443
 - one member instance attached to both pools
 - the loadbalancer is attached to the necessary networks

The required variables (instance, network, auth) are documented in [`vars.tf`](vars.tf) and [.envrc-dist](.envrc-dist).
