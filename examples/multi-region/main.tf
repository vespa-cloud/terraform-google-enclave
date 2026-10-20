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
  version     = ">= 2.3.2, < 3.0.0" # test and staging in europe-west1 were added in 2.3.2
  tenant_name = "<YOUR-TENANT-HERE>"
  # Uncomment to enable SSH access for the Vespa team
  # enable_ssh = true
}

#
# Set up regional resources for each GCP region.
# Use a unique /16 per region within 10.0.0.0/8, then allocate zones within it.
#
module "region_europe_west1" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.3.2, < 3.0.0"
  region          = module.enclave.regions.europe_west1
  proxy_only_cidr = "10.0.0.0/26" # 10.0.0.0 - 10.0.0.63, 64 IPs.
}

module "region_us_central1" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.3.2, < 3.0.0"
  region          = module.enclave.regions.us_central1
  proxy_only_cidr = "10.1.0.0/26" # 10.1.0.0 - 10.1.0.63, 64 IPs.
}

module "region_europe_west3" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.3.2, < 3.0.0"
  region          = module.enclave.regions.europe_west3
  proxy_only_cidr = "10.2.0.0/26" # 10.2.0.0 - 10.2.0.63, 64 IPs.
}

#
# Set up zone-specific networking resources.
#
# CIDR layout — europe-west1 (10.0.0.0/16):
#   10.0.0.0/26    proxy-only (regional)
#   10.0.4.0/22    hosts  (test),    10.0.8.0/22   nodes (test),    10.0.12.0/24 lb+psc (test)
#   10.0.16.0/22   hosts  (staging), 10.0.20.0/22  nodes (staging), 10.0.24.0/24 lb+psc (staging)
#
# CIDR layout — us-central1 (10.1.0.0/16):
#   10.1.0.0/26    proxy-only (regional)
#   10.1.4.0/22    hosts  (prod),    10.1.8.0/22   nodes (prod),    10.1.12.0/24 lb+psc (prod)
#
# CIDR layout — europe-west3 (10.2.0.0/16):
#   10.2.0.0/26    proxy-only (regional)
#   10.2.4.0/22    hosts  (prod),    10.2.8.0/22   nodes (prod),    10.2.12.0/24 lb+psc (prod)
#

#
# First we set up the two zones that are used for the CI/CD deployment pipeline
# that Vespa Cloud supports. The test and staging zones in europe-west1 are
# multi-AZ: a single zone spreads its hosts across all availability zones in
# the region, which makes it much less likely that a pipeline run stalls on
# lack of capacity.
#
# If you already have test and staging zones in us-central1-f, keep them until
# Vespa Cloud has confirmed that your pipeline runs in europe-west1.
#
module "zone_test_europe_west1" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.3.2, < 3.0.0"
  zone                         = module.region_europe_west1.zones.test.gcp_europe_west1
  host_cidr                    = "10.0.4.0/22"    # 10.0.4.0    - 10.0.7.255,   1024 IPs.
  node_cidr                    = "10.0.8.0/22"    # 10.0.8.0    - 10.0.11.255,  1024 IPs.
  lb_cidr                      = "10.0.12.0/25"   # 10.0.12.0   - 10.0.12.127,   128 IPs.
  private_service_connect_cidr = "10.0.12.128/25" # 10.0.12.128 - 10.0.12.255,   128 IPs.
}

module "zone_staging_europe_west1" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.3.2, < 3.0.0"
  zone                         = module.region_europe_west1.zones.staging.gcp_europe_west1
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
  version                      = ">= 2.3.2, < 3.0.0"
  zone                         = module.region_us_central1.zones.prod.gcp_us_central1_f
  host_cidr                    = "10.1.4.0/22"    # 10.1.4.0    - 10.1.7.255,   1024 IPs.
  node_cidr                    = "10.1.8.0/22"    # 10.1.8.0    - 10.1.11.255,  1024 IPs.
  lb_cidr                      = "10.1.12.0/25"   # 10.1.12.0   - 10.1.12.127,   128 IPs.
  private_service_connect_cidr = "10.1.12.128/25" # 10.1.12.128 - 10.1.12.255,   128 IPs.
}

module "zone_prod_europe_west3_b" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.3.2, < 3.0.0"
  zone                         = module.region_europe_west3.zones.prod.gcp_europe_west3_b
  host_cidr                    = "10.2.4.0/22"    # 10.2.4.0    - 10.2.7.255,   1024 IPs.
  node_cidr                    = "10.2.8.0/22"    # 10.2.8.0    - 10.2.11.255,  1024 IPs.
  lb_cidr                      = "10.2.12.0/25"   # 10.2.12.0   - 10.2.12.127,   128 IPs.
  private_service_connect_cidr = "10.2.12.128/25" # 10.2.12.128 - 10.2.12.255,   128 IPs.
}
