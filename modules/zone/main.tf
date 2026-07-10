terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

locals {
  zone_name = "${var.zone.environment}-${var.zone.gcp_zone}"

  # Derived from the computed `id` attribute instead of `project_id` because
  # only computed attributes can be mocked in the smoke test; the values are
  # identical.
  project_id = trimprefix(data.google_project.project.id, "projects/")
}
