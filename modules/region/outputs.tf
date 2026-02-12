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
  value       = var.region.zones
}
