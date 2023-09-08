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
# Set up the VPC that will contain the Enclaved Vespa application.
#

#
# First we set up the two zones that are used for the CI/CD deployment pipeline
# that Vespa Cloud supports.
#
module "zone_test_us_central1_f" {
  source  = "vespa-cloud/enclave/google/modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.test.gcp_us_central1_f
}

module "zone_staging_us_central1_f" {
  source  = "vespa-cloud/enclave/google/modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.staging.gcp_us_central1_f
}

#
# Then we set up two zones that production deployments go to.
# 
module "zone_prod_us_central1_f" {
  source  = "vespa-cloud/enclave/google/modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.prod.gcp_us_central1_f
}

module "zone_prod_europe_west3_b" {
  source  = "vespa-cloud/enclave/google/modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.prod.gcp_europe_west3_b
}
