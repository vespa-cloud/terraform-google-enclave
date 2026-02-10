# Disk encryption resources

resource "google_kms_key_ring" "disk" {
  name     = "${local.zone_name}-vespa-cloud-disk-key"
  location = var.zone.gcp_region
}

resource "google_kms_crypto_key" "disk" {
  #checkov:skip=CKV_GCP_82: No prevent_destroy to allow tenants run terraform destroy
  name            = "disk-encryption"
  key_ring        = google_kms_key_ring.disk.id
  rotation_period = "7776000s" // 90 days
}
