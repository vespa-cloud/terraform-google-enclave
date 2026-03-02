#
# Set up the GCP Terraform Provider to point to the GCP project where you want
# to provision the Vespa Cloud Enclave.
#
provider "google" {
  project = "<YOUR-GCP-PROJECT-HERE>"
}

#
# Set up global project-wide Vespa Cloud Enclave resources.
#
module "enclave" {
  source      = "vespa-cloud/enclave/google"
  version     = ">= 1.0.0, < 2.0.0"
  tenant_name = "<YOUR-TENANT-HERE>"
}

#
# Set up GCP regional resources.
#
module "region_us_central1" {
  source  = "vespa-cloud/enclave/google//modules/region"
  version = ">= 1.0.0, < 2.0.0"
  region  = module.enclave.regions.us_central1
}

#
# Set up Vespa zone resources.
#
module "zone_dev_us_central1_f" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.region_us_central1.zones.dev.gcp_us_central1_f
}
