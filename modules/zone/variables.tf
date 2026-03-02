variable "zone" {
  description = "Vespa Cloud zone to bootstrap"
  type = object({
    environment      = string,
    region           = string,
    gcp_region       = string,
    gcp_zone         = string,
    name             = string,
    globals          = map(any),
    template_version = string,
    proxy_only_cidr  = string,
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

# TODO: propagate service_attachment_cidr to the config server so it knows
# which IP range to draw PSC NAT /29 subnets from.  google_compute_subnetwork
# does not support labels, so the mechanism is TBD (e.g. subnet description,
# a tag on the VPC network, or storing it in ZooKeeper during provisioning).
variable "service_attachment_cidr" {
  description = "Private IPv4 CIDR for NAT subnets on Private Service Connect service attachments"
  type        = string
  validation {
    condition     = try(cidrnetmask(var.service_attachment_cidr) != "" && tonumber(split("/", var.service_attachment_cidr)[1]) <= 29, false)
    error_message = "service_attachment_cidr must be a valid CIDR notation with prefix length /29 or shorter."
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
