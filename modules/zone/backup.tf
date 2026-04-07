# Backup storage for Vespa Cloud snapshots

data "google_storage_project_service_account" "gcs_account" {}

resource "google_storage_bucket" "backup" {
  name                        = "backup-${data.google_project.project.project_id}-${var.zone.environment}-gcp-${var.zone.gcp_zone}"
  location                    = var.zone.regional.gcp_region
  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
  encryption {
    default_kms_key_name = google_kms_crypto_key.backup.id
  }
  depends_on = [google_kms_crypto_key_iam_binding.backup]
}

resource "google_storage_bucket_iam_member" "backup_creator" {
  for_each = toset([
    "roles/storage.objectCreator",
    "roles/storage.objectViewer"
  ])
  bucket = google_storage_bucket.backup.name
  role   = each.value
  member = "serviceAccount:tenant-host@${data.google_project.project.project_id}.iam.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "backup_expirer" {
  bucket = google_storage_bucket.backup.name
  role   = var.zone.globals.backup_role_expiry
  member = "serviceAccount:vespa-cloud-provisioner@${var.vespa_cloud_project}.iam.gserviceaccount.com"
}

resource "google_kms_key_ring" "backup" {
  name     = "host-backup-key-ring-${data.google_project.project.project_id}-${var.zone.environment}-${var.zone.gcp_zone}"
  location = var.zone.regional.gcp_region
}

resource "google_kms_crypto_key" "backup" {
  #checkov:skip=CKV_GCP_82: No prevent_destroy to allow tenants run terraform destroy
  name            = "host-backup-key"
  key_ring        = google_kms_key_ring.backup.id
  rotation_period = "2592000s" # 30 days
}

resource "google_kms_crypto_key_iam_binding" "backup" {
  crypto_key_id = google_kms_crypto_key.backup.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  ]
}
