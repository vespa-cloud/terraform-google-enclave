# Archive resources for log storage

data "google_project" "project" {}

resource "random_string" "archive" {
  length  = 6
  special = false
  upper   = false
}

resource "google_storage_bucket" "archive" {
  name                        = "vespa-archive-${var.zone.environment}-${var.zone.gcp_zone}-${data.google_project.project.number}-${random_string.archive.id}"
  location                    = var.zone.gcp_region
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  lifecycle_rule {
    condition {
      age = 31
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    managedby              = "vespa-cloud"
    vespa_template_version = var.zone.template_version
  }
}

resource "google_storage_bucket_iam_member" "archive_write" {
  bucket = google_storage_bucket.archive.name
  role   = var.zone.globals.archive_role_write
  member = "serviceAccount:tenant-host@${data.google_project.project.project_id}.iam.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "archive_delete" {
  bucket = google_storage_bucket.archive.name
  role   = var.zone.globals.archive_role_delete
  member = "serviceAccount:tenant-host@${data.google_project.project.project_id}.iam.gserviceaccount.com"
  condition {
    title       = "files that are updated"
    description = "Limit delete to files that are updated"
    expression  = "resource.name.endsWith(\"/vespa.log.zst\") || resource.name.endsWith(\"/zookeeper.log.zst\") || resource.name.endsWith(\"/nginx-error.log.zst\")"
  }
}

resource "google_storage_bucket_iam_member" "archive_reader" {
  for_each = toset(var.archive_reader_members)
  bucket   = google_storage_bucket.archive.name
  role     = var.zone.globals.archive_role_delete
  member   = each.value
  condition {
    title       = "files that are updated"
    description = "Limit delete to files that are updated"
    expression  = "resource.name.endsWith(\"/vespa.log.zst\") || resource.name.endsWith(\"/zookeeper.log.zst\") || resource.name.endsWith(\"/nginx-error.log.zst\")"
  }
}
