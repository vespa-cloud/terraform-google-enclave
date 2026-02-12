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
}
