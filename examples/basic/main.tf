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
# proxy_only_cidr is optional.  The default for us-central1 is 10.0.0.0/26.
# Override it if that range conflicts with your existing VPC address space.
#
module "region_us_central1" {
  source  = "vespa-cloud/enclave/google//modules/region"
  version = ">= 1.0.0, < 2.0.0"
  region  = module.enclave.regions.us_central1
  # proxy_only_cidr = "10.0.0.0/26"  # default; override if needed.
}

#
# Set up Vespa zone resources.
#
# All four CIDR variables are optional.  The defaults fit each zone into a /21
# supernet laid out as follows (base address for dev.us-central1-f: 10.0.8.0/21):
#
#   host_cidr               = "10.0.8.0/23"   # cidrsubnet(base, 2, 0)
#   lb_cidr                 = "10.0.10.0/24"  # cidrsubnet(base, 3, 2)
#   node_cidr               = "10.0.12.0/23"  # cidrsubnet(base, 2, 2)
#   service_attachment_cidr = "10.0.14.0/23"  # cidrsubnet(base, 2, 3)
#
# Override any of them if the defaults conflict with your existing VPC address space.
#
module "zone_dev_us_central1_f" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.region_us_central1.zones.dev.gcp_us_central1_f
}
