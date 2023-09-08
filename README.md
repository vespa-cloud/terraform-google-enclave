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
    source = "vespa-cloud/enclave/google"
    tenant_name = "vespa"
}

module "zone_prod_us_central1_f" {
    source = "vespa-cloud/enclave/google/modules/zone"
    zone = module.enclave.zones.prod.gcp_us_central1_f
}

module "zone_prod_europe_west3_b" {
    source = "vespa-cloud/enclave/google/modules/zone"
    zone = module.enclave.zones.prod.gcp_europe_west3_b
}
```

# SSH

To grant the Vespa Cloud operations team low-level SSH access to the hosts inside the Enclave through
[GCP OS Login](https://cloud.google.com/compute/docs/oslogin), set `enable_ssh = true`.

Only enable this if you explicitly wish to grant this access.

```terraform
module "enclave" {
    source      = "vespa-cloud/enclave/google"
    tenant_name = "<vespa cloud tenant>"
    enable_ssh  = true
}
```
