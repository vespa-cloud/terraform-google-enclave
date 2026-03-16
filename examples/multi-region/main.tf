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
  version     = ">= 2.0.0, < 3.0.0"
  tenant_name = "<YOUR-TENANT-HERE>"
  # Uncomment to enable SSH access for the Vespa team
  # enable_ssh = true
}

#
# Set up regional resources for each GCP region.
# Use a unique /16 per region within 10.0.0.0/8, then allocate zones within it.
#
module "region_us_central1" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.0.0, < 3.0.0"
  region          = module.enclave.regions.us_central1
  proxy_only_cidr = "10.0.0.0/26" # 10.0.0.0 - 10.0.0.63, 64 IPs.
}

module "region_europe_west3" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.0.0, < 3.0.0"
  region          = module.enclave.regions.europe_west3
  proxy_only_cidr = "10.1.0.0/26" # 10.1.0.0 - 10.1.0.63, 64 IPs.
}

#
# Set up zone-specific networking resources.
#
# CIDR layout — us-central1 (10.0.0.0/16):
#   10.0.0.0/26    proxy-only (regional)
#   10.0.4.0/22    hosts  (test),    10.0.8.0/22   nodes (test),    10.0.12.0/24 lb+psc (test)
#   10.0.16.0/22   hosts  (staging), 10.0.20.0/22  nodes (staging), 10.0.24.0/24 lb+psc (staging)
#   10.0.28.0/22   hosts  (prod),    10.0.32.0/22  nodes (prod),    10.0.36.0/24 lb+psc (prod)
#
# CIDR layout — europe-west3 (10.1.0.0/16):
#   10.1.0.0/26    proxy-only (regional)
#   10.1.4.0/22    hosts  (prod),    10.1.8.0/22   nodes (prod),    10.1.12.0/24 lb+psc (prod)
#

#
# First we set up the two zones that are used for the CI/CD deployment pipeline
# that Vespa Cloud supports.
#
module "zone_test_us_central1_f" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.0.0, < 3.0.0"
  zone                         = module.region_us_central1.zones.test.gcp_us_central1_f
  host_cidr                    = "10.0.4.0/22"    # 10.0.4.0    - 10.0.7.255,   1024 IPs.
  node_cidr                    = "10.0.8.0/22"    # 10.0.8.0    - 10.0.11.255,  1024 IPs.
  lb_cidr                      = "10.0.12.0/25"   # 10.0.12.0   - 10.0.12.127,   128 IPs.
  private_service_connect_cidr = "10.0.12.128/25" # 10.0.12.128 - 10.0.12.255,   128 IPs.
}

module "zone_staging_us_central1_f" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.0.0, < 3.0.0"
  zone                         = module.region_us_central1.zones.staging.gcp_us_central1_f
  host_cidr                    = "10.0.16.0/22"   # 10.0.16.0   - 10.0.19.255,  1024 IPs.
  node_cidr                    = "10.0.20.0/22"   # 10.0.20.0   - 10.0.23.255,  1024 IPs.
  lb_cidr                      = "10.0.24.0/25"   # 10.0.24.0   - 10.0.24.127,   128 IPs.
  private_service_connect_cidr = "10.0.24.128/25" # 10.0.24.128 - 10.0.24.255,   128 IPs.
}

#
# Then we set up two zones for production deployments.
#
module "zone_prod_us_central1_f" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.0.0, < 3.0.0"
  zone                         = module.region_us_central1.zones.prod.gcp_us_central1_f
  host_cidr                    = "10.0.28.0/22"   # 10.0.28.0   - 10.0.31.255,  1024 IPs.
  node_cidr                    = "10.0.32.0/22"   # 10.0.32.0   - 10.0.35.255,  1024 IPs.
  lb_cidr                      = "10.0.36.0/25"   # 10.0.36.0   - 10.0.36.127,   128 IPs.
  private_service_connect_cidr = "10.0.36.128/25" # 10.0.36.128 - 10.0.36.255,   128 IPs.
}

module "zone_prod_europe_west3_b" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.0.0, < 3.0.0"
  zone                         = module.region_europe_west3.zones.prod.gcp_europe_west3_b
  host_cidr                    = "10.1.4.0/22"    # 10.1.4.0    - 10.1.7.255,   1024 IPs.
  node_cidr                    = "10.1.8.0/22"    # 10.1.8.0    - 10.1.11.255,  1024 IPs.
  lb_cidr                      = "10.1.12.0/25"   # 10.1.12.0   - 10.1.12.127,   128 IPs.
  private_service_connect_cidr = "10.1.12.128/25" # 10.1.12.128 - 10.1.12.255,   128 IPs.
}
