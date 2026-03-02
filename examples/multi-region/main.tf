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
  # Uncomment to enable SSH access for the Vespa team.
  # enable_ssh = true
}

#
# Set up regional Cloud NAT and proxy-only subnet for each GCP region.
# In this example we have zones in us-central1 and europe-west3.
#
# proxy_only_cidr is optional.  Defaults per region (all within 10.0.0.0/9):
#   us-central1  → 10.0.0.0/26
#   us-east4     → 10.1.0.0/26
#   europe-west3 → 10.2.0.0/26
#
# GCP requires at least /26; /23 is recommended for production growth.
# Override if the default conflicts with your existing VPC address space.
#
module "region_us_central1" {
  source  = "vespa-cloud/enclave/google//modules/region"
  version = ">= 1.0.0, < 2.0.0"
  region  = module.enclave.regions.us_central1
  # proxy_only_cidr = "10.0.0.0/26"  # default; override if needed.
}

module "region_europe_west3" {
  source  = "vespa-cloud/enclave/google//modules/region"
  version = ">= 1.0.0, < 2.0.0"
  region  = module.enclave.regions.europe_west3
  # proxy_only_cidr = "10.2.0.0/26"  # default; override if needed.
}

#
# Set up zone-specific networking resources.
#
# All four CIDR variables are optional.  Each zone has a pre-defined /21
# supernet base address.  Within each /21 the layout is:
#
#   base+.0.0/23  — host_cidr               (cidrsubnet(base/21, 2, 0))
#   base+.2.0/24  — lb_cidr                 (cidrsubnet(base/21, 3, 2))
#   base+.4.0/23  — node_cidr               (cidrsubnet(base/21, 2, 2))
#   base+.6.0/23  — service_attachment_cidr (cidrsubnet(base/21, 2, 3))
#
# Default zone bases (us-central1, all within 10.0.0.0/16):
#   test.us-central1-f    → 10.0.16.0/21
#   staging.us-central1-f → 10.0.24.0/21
#   prod.us-central1-f    → 10.0.64.0/21
# Default zone base (europe-west3):
#   prod.europe-west3-b   → 10.2.8.0/21
#
# Override any CIDR if the default conflicts with your existing address space.
#

#
# Two zones used for the CI/CD deployment pipeline.
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
# Two production zones, one in each region.
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
