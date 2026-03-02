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
  description = "Private IPv4 CIDR for the VM subnetwork. Defaults to a pre-defined /23 based on the zone."
  type        = string
  default     = null
  validation {
    condition     = var.host_cidr == null || try(cidrnetmask(var.host_cidr) != "" && tonumber(split("/", var.host_cidr)[1]) <= 29, false)
    error_message = "host_cidr must be a valid CIDR notation with prefix length /29 or shorter (e.g. \"10.0.8.0/23\")."
  }
}

variable "node_cidr" {
  description = "Private IPv4 CIDR for the containers on the VMs. Defaults to a pre-defined /23 based on the zone (0-bit container suffix = exclusive allocation)."
  type        = string
  default     = null
  validation {
    condition     = var.node_cidr == null || try(cidrnetmask(var.node_cidr) != "" && tonumber(split("/", var.node_cidr)[1]) <= 29, false)
    error_message = "node_cidr must be a valid CIDR notation with prefix length /29 or shorter (e.g. \"10.0.12.0/23\")."
  }
}

variable "service_attachment_cidr" {
  description = "Private IPv4 CIDR for NAT subnets on Private Service Connect service attachments. Defaults to a pre-defined /23 based on the zone."
  type        = string
  default     = null
  validation {
    condition     = var.service_attachment_cidr == null || try(cidrnetmask(var.service_attachment_cidr) != "" && tonumber(split("/", var.service_attachment_cidr)[1]) <= 29, false)
    error_message = "service_attachment_cidr must be a valid CIDR notation with prefix length /29 or shorter."
  }
}

variable "lb_cidr" {
  description = "Private IPv4 CIDR for the subnetwork of the forwarding rule on private endpoints. Defaults to a pre-defined /24 based on the zone."
  type        = string
  default     = null
  validation {
    condition     = var.lb_cidr == null || try(cidrnetmask(var.lb_cidr) != "" && tonumber(split("/", var.lb_cidr)[1]) <= 29, false)
    error_message = "lb_cidr must be a valid CIDR notation with prefix length /29 or shorter."
  }
}

resource "terraform_data" "validate_cidrs" {
  lifecycle {
    # Fail early with a clear message if no default exists for this zone and no
    # explicit value was provided.
    precondition {
      condition     = local.host_cidr != null && local.node_cidr != null && local.lb_cidr != null && local.service_attachment_cidr != null
      error_message = "No default CIDR is defined for zone '${local._zone_key}'. Provide host_cidr, node_cidr, lb_cidr, and service_attachment_cidr explicitly."
    }

    # Allow host_cidr and node_cidr to differ by at most 5 prefix bits so that
    # at most 32 containers can be placed on each VM.  Equal prefix lengths
    # (0 extra bits) means exclusive allocation: exactly one container per VM.
    precondition {
      condition = local.host_cidr == null || local.node_cidr == null || (
        tonumber(split("/", local.host_cidr)[1]) - tonumber(split("/", local.node_cidr)[1]) >= 0 &&
        tonumber(split("/", local.host_cidr)[1]) - tonumber(split("/", local.node_cidr)[1]) <= 5
      )
      error_message = "The node CIDR must be between 0 to 5 bits larger than the host CIDR."
    }
  }
}
