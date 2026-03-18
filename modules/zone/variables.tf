variable "zone" {
  description = "Vespa Cloud zone to bootstrap"
  type = object({
    environment = string,
    region      = string,
    gcp_zone    = string,
    name        = string,
    globals = object({
      archive_role_write  = string
      archive_role_delete = string
      vpc_id              = string
      vpc_name            = string
      vpc_self_link       = string
    }),
    template_version = string,
    regional = object({
      gcp_region      = string
      proxy_only_cidr = string
    }),
  })
}

variable "archive_reader_members" {
  description = "List of members allowed to read archive bucket in the format `type:principal`. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam#argument-reference for more details."
  type        = list(string)
  default     = []
}

variable "host_cidr" {
  description = "Private IPv4 CIDR for the VM subnetwork"
  type        = string
  validation {
    condition     = try(cidrnetmask(var.host_cidr) != "" && tonumber(split("/", var.host_cidr)[1]) <= 29, false)
    error_message = "host_cidr must be a valid CIDR notation with prefix length /29 or shorter (e.g. \"10.128.0.0/22\")."
  }
}

variable "node_cidr" {
  description = "Private IPv4 CIDR for the containers on the VMs"
  type        = string
  validation {
    condition     = try(cidrnetmask(var.node_cidr) != "" && tonumber(split("/", var.node_cidr)[1]) <= 29, false)
    error_message = "node_cidr must be a valid CIDR notation with prefix length /29 or shorter (e.g. \"10.128.128.0/17\")."
  }
}

variable "private_service_connect_cidr" {
  description = "Private IPv4 CIDR for Private Service Connect NAT subnets on service attachments"
  type        = string
  validation {
    condition     = try(cidrnetmask(var.private_service_connect_cidr) != "" && tonumber(split("/", var.private_service_connect_cidr)[1]) <= 29, false)
    error_message = "private_service_connect_cidr must be a valid CIDR notation with prefix length /29 or shorter."
  }
}

variable "lb_cidr" {
  description = "Private IPv4 CIDR for the subnetwork of the forwarding rule on private endpoints"
  type        = string
  validation {
    condition     = try(cidrnetmask(var.lb_cidr) != "" && tonumber(split("/", var.lb_cidr)[1]) <= 29, false)
    error_message = "lb_cidr must be a valid CIDR notation with prefix length /29 or shorter."
  }
}

resource "terraform_data" "validate_node_cidr" {
  lifecycle {
    precondition {
      condition = (
        tonumber(split("/", var.host_cidr)[1]) - tonumber(split("/", var.node_cidr)[1]) >= 0 &&
        tonumber(split("/", var.host_cidr)[1]) - tonumber(split("/", var.node_cidr)[1]) <= 5
      )
      error_message = "The node CIDR must be between 0 to 5 bits larger than the host CIDR"
    }
  }
}
