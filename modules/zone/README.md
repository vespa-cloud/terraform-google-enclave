# Zone Module (Vespa Zones)

This module creates zonal resources for Vespa Cloud Enclave.

In Vespa Cloud each deployment of a Vespa application goes into a (Vespa Cloud)
[zone](https://cloud.vespa.ai/en/reference/zones). A zone hosted on Google Cloud Platform is
always contained within one
[GCP zone](https://docs.cloud.google.com/compute/docs/regions-zones).

For each Vespa Cloud zone you want to deploy to, you must configure a module of this type.

For this module to work, both the top-level (enclave) module and the regional module must be configured first.


Example use:
```terraform
provider "google" {
    project = "my-gcp-project"
}

module "enclave" {
    source = "vespa-cloud/enclave/google"
    version = ">= 2.0.0, < 3.0.0"
    tenant_name = "vespa"
}

# Create regional resources (required)
module "region_us_central1" {
    source = "vespa-cloud/enclave/google//modules/region"
    version = ">= 2.0.0, < 3.0.0"
    region = module.enclave.regions.us_central1
}

# Create zone-specific resources (reference zone from region module)
module "zone_prod_us_central1_f" {
    source = "vespa-cloud/enclave/google//modules/zone"
    version = ">= 2.0.0, < 3.0.0"
    zone = module.region_us_central1.zones.prod.gcp_us_central1_f
}
```
