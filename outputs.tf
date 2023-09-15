
locals {
  template_version = "1_0_1" # '.' not allowed in labels
  all_zones = var.is_cd ? [
    { environment = "dev", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "test", gcp_region = "us-central1", gcp_zone = "us-central1-f", },
    { environment = "staging", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "prod", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    ] : [
    { environment = "dev", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "test", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "staging", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "perf", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "prod", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "prod", gcp_region = "europe-west3", gcp_zone = "europe-west3-b" },
  ]
  zones_by_env = {
    for zone in local.all_zones :
    zone.environment => merge({
      name             = "${zone.environment}.${zone.gcp_zone}",
      region           = "gcp-${zone.gcp_zone}",
      is_cd            = var.is_cd,
      resource_ids     = module.provision.resource_ids,
      template_version = local.template_version,
    }, zone)...
  }
}

output "zones" {
  value = {
    for environment, zones in local.zones_by_env :
    environment => { for zone in zones : replace(zone.region, "-", "_") => zone }
  }

  depends_on = [module.provision]
}

output "vespa_cloud_project" {
  value = local.vespa_cloud_project
}
