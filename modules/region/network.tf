# Regional networking resources

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
  ip_cidr_range = var.proxy_only_cidr
  region        = var.region.gcp_region
  network       = var.region.globals.vpc_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

