# Test fixture: composes the root module with the customer-facing submodules,
# mirroring the multi-region example, but with relative sources so the local
# (unreleased) code is what gets planned.

module "enclave" {
  source      = "../.."
  tenant_name = "vespa"
  enable_ssh  = true
}

module "region_us_central1" {
  source          = "../../modules/region"
  region          = module.enclave.regions.us_central1
  proxy_only_cidr = "10.0.0.0/26"
}

module "zone_prod_us_central1_f" {
  source                       = "../../modules/zone"
  zone                         = module.region_us_central1.zones.prod.gcp_us_central1_f
  host_cidr                    = "10.0.28.0/22"
  node_cidr                    = "10.0.32.0/22"
  lb_cidr                      = "10.0.36.0/25"
  private_service_connect_cidr = "10.0.36.128/25"
  archive_reader_members = [
    "serviceAccount:vespa-operator@vespa-external.iam.gserviceaccount.com",
  ]
}

output "zones" {
  value = module.region_us_central1.zones
}

output "router_name" {
  value = module.region_us_central1.router_name
}
