variable "tenant_name" {
  description = "The tenant name of the owner of the GCP project"
  type        = string
}

variable "enable_ssh" {
  description = "Grant Vespa operators SSH access to instances running in Enclave project"
  type        = bool
  default     = false
}

variable "vespa_cloud_project" {
  description = "The project the Vespa Cloud provisioner resides in"
  type        = string
  default     = "vespa-external"
}

variable "all_zones" {
  description = "All Vespa Cloud zones"
  type = list(object({
    environment = string
    gcp_region  = string
    gcp_zone    = string
  }))
  default = [
    { environment = "dev", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "test", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "staging", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "perf", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "prod", gcp_region = "us-central1", gcp_zone = "us-central1-a" },
    { environment = "prod", gcp_region = "us-central1", gcp_zone = "us-central1-b" },
    { environment = "prod", gcp_region = "us-central1", gcp_zone = "us-central1-c" },
    { environment = "prod", gcp_region = "us-central1", gcp_zone = "us-central1-f" },
    { environment = "prod", gcp_region = "europe-west3", gcp_zone = "europe-west3-b" },
  ]
}
