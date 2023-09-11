In Vespa Cloud each deployment of a Vespa application goes into a zone. Zones
hosted on Google Cloud Platform are always contained within one Zone.

An Enclave VPC of Vespa Cloud must be located in the same Zone as the
configuration servers managing that Enclave VPC. This ensures that fail-over
between Zones can be maintained and reduces the risk of down time on the Vespa
application.

For each Enclave VPC that is needed, an instance of this module must be
configured.

For this module to work the top-level module must also be configured.


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
    source = "vespa-cloud/enclave/google//modules/zone"
    zone = module.enclave.zones.prod.gcp_us_central1_f
}
```
