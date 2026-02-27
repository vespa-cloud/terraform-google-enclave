variable "region" {
  description = "GCP region configuration with global resource references and zones in this region"
  type = object({
    gcp_region       = string,
    globals          = map(any),
    template_version = string,
    zones            = map(any),
  })
}

variable "proxy_only_cidr" {
  description = "Private IPv4 CIDR for the regional Envoy-based load balancers, used by private endpoints"
  type        = string
  # GCP recommends a /23 for the proxy-only subnet to allow future growth.
  # See https://cloud.google.com/load-balancing/docs/proxy-only-subnets#proxy_only_subnet_create
  validation {
    condition     = try(cidrnetmask(var.proxy_only_cidr) != "" && tonumber(split("/", var.proxy_only_cidr)[1]) <= 26, false)
    error_message = "proxy_only_cidr must be a valid CIDR notation with prefix length /26 or shorter."
  }
}