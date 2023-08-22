# Vespa Cloud Enclave Terraform

This Terraform module handles bootstrapping of a GCP project such that
it can be part of a Vespa Cloud Enclave.

After declaring the providers, set up the global `enclave` module.
This module configures the global GCP resources like IAM roles and
service accounts needed to get started.

Then for each Enclave you want to host in your project - declare the
`zone` module for each Vespa Cloud zone you need.  

Example use:
```terraform
provider "google" {
  project = "my-gcp-project"
}

module "enclave" {
    source = "vespa-cloud/terraform-gcp-enclave"
    tenant_name = "vespa"
}

module "zone_prod_us_central1_f" {
    source = "vespa-cloud/terraform-gcp-enclave/modules/zone"
    zone = module.enclave.zones.prod.gcp_us_central1_f
}

module "zone_prod_europe_west3_b" {
    source = "vespa-cloud/terraform-gcp-enclave/modules/zone"
    zone = module.enclave.zones.prod.gcp_europe_west3_b
}
```
