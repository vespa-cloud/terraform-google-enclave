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

  # Lookup key used to find this zone's default /21 supernet base address.
  _zone_key = "${var.zone.environment}.${var.zone.gcp_zone}"

  # Default /21 base address per (environment, gcp_zone) pair.
  # Each zone is allocated an 8 × /24 supernet laid out as:
  #   base+.0.0/23  → host_cidr               (cidrsubnet(base/21, 2, 0))
  #   base+.2.0/24  → lb_cidr                 (cidrsubnet(base/21, 3, 2))
  #   base+.4.0/23  → node_cidr               (cidrsubnet(base/21, 2, 2))
  #   base+.6.0/23  → service_attachment_cidr (cidrsubnet(base/21, 2, 3))
  # The unused base+.3.0/24 slot is reserved for a regional proxy-only subnet
  # when a customer wishes to keep it inside the same /21 supernet.
  # All ranges are within 10.0.0.0/9, avoiding the 10.128.0.0/9 block that GCP
  # advises against for subnet primary/secondary ranges.
  _default_zone_bases = {
    # us-central1 – each environment/zone gets a unique /21 starting at .8.0
    # to leave room for the per-region proxy-only /26 at 10.0.0.0/26.
    "dev.us-central1-f"     = "10.0.8.0"
    "test.us-central1-f"    = "10.0.16.0"
    "staging.us-central1-f" = "10.0.24.0"
    "perf.us-central1-f"    = "10.0.32.0" # deprecated; kept for backwards compatibility.
    "prod.us-central1-a"    = "10.0.40.0"
    "prod.us-central1-b"    = "10.0.48.0"
    "prod.us-central1-c"    = "10.0.56.0"
    "prod.us-central1-f"    = "10.0.64.0"
    # us-east4 – proxy-only at 10.1.0.0/26, zones from 10.1.8.0.
    "prod.us-east4-c"       = "10.1.8.0"
    # europe-west3 – proxy-only at 10.2.0.0/26, zones from 10.2.8.0.
    "prod.europe-west3-b"   = "10.2.8.0"
  }

  # Resolved /21 base CIDR for this zone, or null if not in the table.
  _base_cidr = (
    contains(keys(local._default_zone_bases), local._zone_key)
    ? "${local._default_zone_bases[local._zone_key]}/21"
    : null
  )

  # Final CIDR values: explicit variable takes precedence, then computed default.
  host_cidr               = var.host_cidr != null ? var.host_cidr : (local._base_cidr != null ? cidrsubnet(local._base_cidr, 2, 0) : null)
  lb_cidr                 = var.lb_cidr != null ? var.lb_cidr : (local._base_cidr != null ? cidrsubnet(local._base_cidr, 3, 2) : null)
  node_cidr               = var.node_cidr != null ? var.node_cidr : (local._base_cidr != null ? cidrsubnet(local._base_cidr, 2, 2) : null)
  service_attachment_cidr = var.service_attachment_cidr != null ? var.service_attachment_cidr : (local._base_cidr != null ? cidrsubnet(local._base_cidr, 2, 3) : null)
}
