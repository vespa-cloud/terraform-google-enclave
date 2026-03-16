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
  version     = ">= 2.0.0, < 3.0.0"
  tenant_name = "<YOUR-TENANT-HERE>"
}

#
# Set up GCP regional resources.
#
module "region_us_central1" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.0.0, < 3.0.0"
  region          = module.enclave.regions.us_central1
  proxy_only_cidr = "10.0.0.0/26" # 10.0.0.0 - 10.0.0.63, 64 IPs.
}

#
# Set up Vespa zone resources.
#
# CIDR layout for us-central1:
#   10.0.0.0/26    proxy-only (regional)
#   10.0.4.0/22    hosts      (dev)
#   10.0.8.0/22    nodes      (dev)
#   10.0.12.0/25   lb         (dev)
#   10.0.12.128/25 psc        (dev)
#
module "zone_dev_us_central1_f" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.0.0, < 3.0.0"
  zone                         = module.region_us_central1.zones.dev.gcp_us_central1_f
  host_cidr                    = "10.0.4.0/22"    # 10.0.4.0    - 10.0.7.255,   1024 IPs.
  node_cidr                    = "10.0.8.0/22"    # 10.0.8.0    - 10.0.11.255,  1024 IPs.
  lb_cidr                      = "10.0.12.0/25"   # 10.0.12.0   - 10.0.12.127,   128 IPs.
  private_service_connect_cidr = "10.0.12.128/25" # 10.0.12.128 - 10.0.12.255,   128 IPs.
}
