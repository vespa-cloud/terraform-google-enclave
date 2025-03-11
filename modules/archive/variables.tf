
variable "zone" {
  description = "Vespa Cloud zone to bootstrap"
  type = object({
    environment      = string,
    region           = string,
    gcp_region       = string,
    gcp_zone         = string,
    name             = string,
    resource_ids     = map(any),
    template_version = string,
  })
}

variable "reader_members" {
  description = "List of members allowed to read archive bucket in the format `type:principal`. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam#argument-reference for more details."
  type        = list(string)
  default     = []
}
