
variable "is_cd" {
  description = "Whether this terraform part of the Vespa Cloud CI/CD pipeline"
  type        = bool
  default     = false
}

variable "tenant_name" {
  description = "The tenant owner running enclave account"
  type        = string
}

variable "enable_ssh" {
  type    = bool
  default = false
}
