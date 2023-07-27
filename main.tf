
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

locals {
  vespa_cloud_project = var.is_cd ? "vespa-external-cd" : "vespa-external"
}

module "provision" {
  source              = "./modules/provision"
  vespa_cloud_project = local.vespa_cloud_project
  tenant_name         = var.tenant_name
}
