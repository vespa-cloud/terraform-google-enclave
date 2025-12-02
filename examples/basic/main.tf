#
# Set up the GCP Terraform Provider to point to the GCP project where you want
# to provision the Vespa Cloud Enclave.
#
provider "google" {
  project = "<YOUR-GCP-PROJECT-HERE>"
}

#
# Set up the basic module that grants Vespa Cloud permission to provision Vespa
# Cloud resources inside the GCP project.
#
module "enclave" {
  source      = "vespa-cloud/enclave/google"
  version     = ">= 1.0.0, < 2.0.0"
  tenant_name = "<YOUR-TENANT-HERE>"
}

#
# Set up the VPC that will contain the Enclaved Vespa application for the dev environment.
#
module "zone_dev_us_central1_f" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.dev.gcp_us_central1_f
}

#
# Set up the VPC that will contain the Enclaved Vespa application for the perf environment.
#
module "zone_perf_us_central1_f" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.perf.gcp_us_central1_f
}
