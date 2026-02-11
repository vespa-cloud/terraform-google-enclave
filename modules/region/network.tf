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
