# Region Module

This module creates regional resources for Vespa Cloud Enclave.

Each Vespa zone you want to deploy to is located in a GCP region, and each such GCP region requires this module.

Example usage:

```hcl
# Create regional resources.
module "region_us_central1" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.0.0, < 3.0.0"
  region          = module.enclave.regions.us_central1
  proxy_only_cidr = "10.0.0.0/26"
}

# Create zone-specific resources (reference zones from the region module).
module "zone_dev_us_central1_f" {
  source                  = "vespa-cloud/enclave/google//modules/zone"
  version                 = ">= 2.0.0, < 3.0.0"
  zone                    = module.region_us_central1.zones.dev.gcp_us_central1_f
  host_cidr               = "10.0.8.0/23"
  lb_cidr                 = "10.0.10.0/24"
  node_cidr               = "10.0.12.0/23"
  service_attachment_cidr = "10.0.14.0/23"
}
```

## Inputs

- `region` (object, required): GCP region configuration from the root module's `regions` output.
- `proxy_only_cidr` (string, required): Private IPv4 CIDR for the regional Envoy-based load balancers
  used by private endpoints.  GCP requires `/26` or shorter prefix (i.e. a range of at least 64
  addresses); `/23` is recommended for production workloads to accommodate growth.  A single
  proxy-only subnet is shared across all Vespa zones in the same GCP region.  Avoid the
  `10.128.0.0/9` block as GCP discourages its use for subnet primary/secondary ranges.
