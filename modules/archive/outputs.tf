
output "bucket" {
  description = "Name of Vespa Cloud Enclave archive bucket"
  value       = google_storage_bucket.archive.name
}
