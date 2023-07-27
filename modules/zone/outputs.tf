output "network_name" {
  value = google_compute_network.vpc_network.name
}
output "hosts_cidr_block" {
  value = local.hosts_cidr_block
}
output "hosts_ipv6_cidr_block" {
  value = google_compute_subnetwork.subnetwork.ipv6_cidr_range
}
output "hosts_subnet_id" {
  value = google_compute_subnetwork.subnetwork.id
}
