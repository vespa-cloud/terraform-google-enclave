# Region Module

This module creates regional resources for Vespa Cloud Enclave.

Each Vespa zone you want to deploy to is located in a GCP region, and each such GCP region requires this module.

Example usage:

```hcl
# Create regional resources
module "region_us_central1" {
  source  = "vespa-cloud/enclave/google//modules/region"
  version = ">= 2.0.0, < 3.0.0"
  region  = module.enclave.regions.us_central1
}

# Create zone-specific resources (reference zones from the region module)
module "zone_dev_us_central1_f" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 2.0.0, < 3.0.0"
  zone    = module.region_us_central1.zones.dev.gcp_us_central1_f
}
```

## Inputs

- `region` (object, required): GCP region configuration from the root module's `regions` output.
