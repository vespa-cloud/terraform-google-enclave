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
      zone_key => merge(zone_data, { proxy_only_cidr = local.proxy_only_cidr })
    }
  }
}
