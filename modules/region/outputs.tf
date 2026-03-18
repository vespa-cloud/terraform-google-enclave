output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.nat.name
}

output "nat_name" {
  description = "Name of the Cloud NAT gateway"
  value       = google_compute_router_nat.nat_dynamic.name
}

output "zones" {
  description = "Map of Vespa zones available in this GCP region"
  value = {
    for env, zone_map in var.region.zones :
    env => {
      for zone_key, zone_data in zone_map :
      zone_key => {
        name             = "${zone_data.environment}.${zone_data.gcp_zone}"
        environment      = zone_data.environment
        region           = "gcp-${zone_data.gcp_zone}"
        gcp_zone         = zone_data.gcp_zone
        gcp_region       = zone_data.gcp_region
        globals          = var.region.globals
        template_version = var.region.template_version
        regional = {
          gcp_region      = var.region.gcp_region
          proxy_only_cidr = var.proxy_only_cidr
        }
      }
    }
  }
}
