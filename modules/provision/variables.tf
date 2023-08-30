
variable "vespa_cloud_project" {
  description = "The project the Vespa Cloud provisioner resides in"
  type        = string
}

variable "tenant_name" {
  description = "The tenant owner running Enclave project"
  type        = string
}

variable "enable_ssh" {
  description = "Grant Vespa operators SSH access to instances running in Enclave project"
  type        = bool
}
