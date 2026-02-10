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
  # Uncomment to enable SSH access for the Vespa team
  # enable_ssh = true
}

#
# Set up regional Cloud NAT resources for each GCP region.
# In this example we have zones in us-central1 and europe-west3.
#
module "region_us_central1" {
  source  = "vespa-cloud/enclave/google//modules/region"
  version = ">= 1.0.0, < 2.0.0"
  region  = module.enclave.regions.us_central1
}

module "region_europe_west3" {
  source  = "vespa-cloud/enclave/google//modules/region"
  version = ">= 1.0.0, < 2.0.0"
  region  = module.enclave.regions.europe_west3
}

#
# Set up zone-specific networking resources.
#

#
# First we set up the two zones that are used for the CI/CD deployment pipeline
# that Vespa Cloud supports.
#
module "zone_test_us_central1_f" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.region_us_central1.zones.test.gcp_us_central1_f
}

module "zone_staging_us_central1_f" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.region_us_central1.zones.staging.gcp_us_central1_f
}

#
# Then we set up two zones that production deployments go to.
#
module "zone_prod_us_central1_f" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.region_us_central1.zones.prod.gcp_us_central1_f
}

module "zone_prod_europe_west3_b" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.region_europe_west3.zones.prod.gcp_europe_west3_b
}
