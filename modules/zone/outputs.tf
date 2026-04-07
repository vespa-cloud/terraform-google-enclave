output "hosts_cidr_block" {
  value = var.host_cidr
}
output "hosts_ipv6_cidr_block" {
  value = google_compute_subnetwork.subnet_tenant.ipv6_cidr_range
}
output "hosts_subnet_id" {
  value = google_compute_subnetwork.subnet_tenant.id
}
output "archive_bucket" {
  description = "Name of Vespa Cloud Enclave archive bucket"
  value       = google_storage_bucket.archive.name
}
output "backup_bucket" {
  description = "Name of Vespa Cloud Enclave backup bucket"
  value       = google_storage_bucket.backup.name
}
