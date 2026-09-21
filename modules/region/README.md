# Region Module

This module creates regional resources for Vespa Cloud Enclave.

Each Vespa Cloud zone you want to deploy to is located in a GCP region, and each such GCP region
requires one instance of this module.

For this module to work, the top-level (enclave) module must be configured first.

Example usage:

```hcl
# Create regional resources
module "region_us_central1" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.0.0, < 3.0.0"
  region          = module.enclave.regions.us_central1
  proxy_only_cidr = "10.0.0.0/26"
}

# Create zone-specific resources (reference zones from the region module)
module "zone_dev_us_central1_f" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.0.0, < 3.0.0"
  zone                         = module.region_us_central1.zones.dev.gcp_us_central1_f
  host_cidr                    = "10.0.4.0/22"
  node_cidr                    = "10.0.8.0/22"
  lb_cidr                      = "10.0.12.0/25"
  private_service_connect_cidr = "10.0.12.128/25"
}
```

See the root module README for CIDR planning guidance.

## Inputs

- `region` (object, required): GCP region configuration from the root module's `regions` output,
  e.g. `module.enclave.regions.us_central1`.
- `proxy_only_cidr` (string, required): Private IPv4 CIDR for the proxy-only subnet. Must be `/26`
  or shorter. Recommended: `/26` (64 IPs) per region.

## Outputs

- `zones` (map): The Vespa Cloud zones in this region, with `-` replaced by `_`, e.g. `zones.prod.gcp_us_central1_f`. Pass a zone
  object to the `zone` input of `modules/zone`.
