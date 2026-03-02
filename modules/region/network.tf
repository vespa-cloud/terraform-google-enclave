# Regional networking resources

locals {
  # Default proxy-only /26 per GCP region, one per VPC+region as required by GCP.
  # Each default is placed at the very start of its per-region /16 block so that
  # the remainder (.8.0 onwards) is free for per-zone /21 supernets.
  # All ranges are within 10.0.0.0/9 (avoiding the 10.128.0.0/9 block GCP
  # advises against for subnet primary/secondary ranges).
  _default_proxy_only_cidrs = {
    "us-central1"  = "10.0.0.0/26"
    "us-east4"     = "10.1.0.0/26"
    "europe-west3" = "10.2.0.0/26"
  }

  proxy_only_cidr = (
    var.proxy_only_cidr != null
    ? var.proxy_only_cidr
    : local._default_proxy_only_cidrs[var.region.gcp_region]
  )
}

resource "google_compute_router" "nat" {
  name    = "${var.region.globals.vpc_name}-${var.region.gcp_region}-router-nat-gw"
  region  = var.region.gcp_region
  network = var.region.globals.vpc_id
}

resource "google_compute_router_nat" "nat_dynamic" {
  name                               = google_compute_router.nat.name
  router                             = google_compute_router.nat.name
  region                             = google_compute_router.nat.region
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  nat_ip_allocate_option              = "AUTO_ONLY"
  enable_endpoint_independent_mapping = false # Not supported with dynamic IPs

  enable_dynamic_port_allocation = true
}

resource "google_compute_subnetwork" "proxy_only_subnetwork" {
  # checkov:skip=CKV_GCP_74:TCP proxy subnetwork is used for ServiceConnect
  # checkov:skip=CKV_GCP_76:TCP proxy subnetwork is used for ServiceConnect
  name          = "${var.region.gcp_region}-subnet-tcp-proxy-only"
  ip_cidr_range = local.proxy_only_cidr
  region        = var.region.gcp_region
  network       = var.region.globals.vpc_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_region_health_check" "tenant_health_check" {
  name   = "${var.region.globals.vpc_name}-${var.region.gcp_region}-healthcheck-tenant"
  region = var.region.gcp_region

  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 2

  https_health_check {
    port         = 4443
    request_path = "/status.html"
    proxy_header = "PROXY_V1"
  }
}
