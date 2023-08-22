terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

data "google_project" "project" {}

resource "random_string" "archive" {
  length   = 6
  special  = false
  upper    = false
}

resource "google_storage_bucket" "archive" {
  name          = "vespa-archive-${var.zone.environment}-${var.zone.gcp_zone}-${data.google_project.project.number}-${random_string.archive.id}"
  location      = var.zone.gcp_region
  force_destroy = false
  uniform_bucket_level_access = true
  public_access_prevention = "enforced"
  lifecycle_rule {
    condition {
      age = 31
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    managedby = "vespa-cloud"
  }
}

resource "google_project_iam_custom_role" "archive_object_writer" {
  role_id     = "archive_object_writer_${var.zone.environment}_${replace(var.zone.gcp_zone, "-", "_")}"
  title       = "Archive object writer role"
  description = "Allows writing objects to the archive bucket"
  permissions = [
    "storage.objects.create",
    "storage.multipartUploads.create",
    "storage.multipartUploads.abort",
    "storage.multipartUploads.listParts",
  ]
}

resource "google_storage_bucket_iam_member" "archive_writer" {
  bucket = google_storage_bucket.archive.name
  role   = google_project_iam_custom_role.archive_object_writer.id
  member = "serviceAccount:tenant-host@${data.google_project.project.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_custom_role" "archive_object_deleter" {
  role_id     = "archive_object_deleter_${var.zone.environment}_${replace(var.zone.gcp_zone, "-", "_")}"
  title       = "Archive object deleter role"
  description = "Archive object deleter role to grant object delete access"
  permissions = [
    "storage.objects.delete"
  ]
}

resource "google_storage_bucket_iam_member" "archive_deleter" {
  bucket = google_storage_bucket.archive.name
  role   = google_project_iam_custom_role.archive_object_deleter.id
  member = "serviceAccount:tenant-host@${data.google_project.project.project_id}.iam.gserviceaccount.com"
  condition {
    title       = "files that are updated"
    description = "Limit delete to files that are updated"
    expression  = "resource.name.endsWith(\"/vespa.log.zst\") || resource.name.endsWith(\"/zookeeper.log.zst\")"
  }
}
