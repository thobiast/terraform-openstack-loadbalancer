#################################################
#### All computed maps used across the module ###
#################################################
locals {
  # Build a deterministic map for member resources.
  # Key pattern: "${pool_key}/${member_key}"
  # Used as the for_each key in member resources (e.g. "pool-web/instance1").
  #
  # Example output:
  # {
  #   "pool-web/instance1" = {
  #     pool_key  = "pool-web"
  #     member    = { address = "192.0.2.10", protocol_port = 80, ... }
  #   },
  #   "pool-web/instance2" = {
  #     pool_key  = "pool-web"
  #     member    = { address = "192.0.2.11", protocol_port = 80, ... }
  #   }
  # }
  members_by_key = merge([
    for pool_key, pool in var.pools : {
      for member_key, m in pool.members :
      "${pool_key}/${member_key}" => {
        pool_key = pool_key
        member   = m
      }
    }
  ]...)

  # Composite listener-policies into a single map, where each key
  # identifies a policy under its listener.
  #
  # Key pattern: "${listener_key}/${policy_key}"
  #
  # Example output:
  # {
  #   "listener-http/policy-redirect" = {
  #     listener_key = "listener-http"
  #     policy_key   = "policy-redirect"
  #     policy       = { action = "REDIRECT_TO_URL", redirect_url = "https://example.com", ... }
  #   },
  #   "listener-http/policy-api" = {
  #     listener_key = "listener-http"
  #     policy_key   = "policy-api"
  #     policy       = { action = "REDIRECT_TO_POOL", redirect_pool_key = "pool-api", ... }
  #   }
  # }
  l7policies_by_key = merge([
    for listener_key, policies in var.l7policies : {
      for policy_key, policy in policies :
      "${listener_key}/${policy_key}" => {
        listener_key = listener_key
        policy_key   = policy_key
        policy       = policy
      }
    }
  ]...)

  # Composite policy-rules into a single map so each rule is linked
  # to its parent policy and listener.
  #
  # Key pattern: "${listener_key}/${policy_key}/${rule_key}"
  #
  # Example output:
  # {
  #   "listener-http/policy-api/rule-path" = {
  #     l7policy_key = "listener-http/policy-api"  # parent link (matches l7policies_by_key key)
  #     rule         = { type = "PATH", compare_type = "STARTS_WITH", value = "/api", ... }
  #   }
  # }
  l7rules_by_key = merge([
    for l7policy_full_key, pol in local.l7policies_by_key : {
      for rule_key, rule in try(pol.policy.rules, {}) :
      "${l7policy_full_key}/${rule_key}" => {
        l7policy_key = l7policy_full_key
        rule         = rule
      }
    }
  ]...)
}


###############################################################
### Validation locals. Used in resource preconditions       ###
###                                                         ###
### Perform Cross-variable integrity checks for user inputs ###
### Ensure references point to existing map keys            ###
###############################################################
locals {
  # Listeners: if a listener sets default_pool_key,
  # it must reference a key in var.pools
  _bad_default_pool_refs = [
    for l_key, l in var.listeners :
    l_key
    if try(l.default_pool_key, null) != null
    && !contains(keys(var.pools), l.default_pool_key)
  ]
  # L7 policies: when action == REDIRECT_TO_POOL,
  # redirect_pool_key must be set and must reference a key in var.pools
  _bad_redirect_policies = flatten([
    for listener_key, policies in var.l7policies : [
      for policy_key, policy in policies :
      "${listener_key}/${policy_key}"
      if upper(policy.action) == "REDIRECT_TO_POOL" && (
        policy.redirect_pool_key == null ||
        !contains(
          keys(var.pools),
          policy.redirect_pool_key == null ? "" : policy.redirect_pool_key
        )
      )
    ]
  ])
  # L7 policies: each policy must target an existing listener via listener_key.
  # Ensure each policy’s listener_key exists in var.listeners
  _bad_listener_refs_in_policies = [
    for listener_key, _ in var.l7policies :
    listener_key
    if !contains(keys(var.listeners), listener_key)
  ]
}
