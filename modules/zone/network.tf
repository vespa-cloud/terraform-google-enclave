# Networking resources for Vespa zone

resource "google_compute_subnetwork" "subnetwork" {
  name          = "${local.zone_name}-subnet-tenant-host"
  ip_cidr_range = var.host_cidr
  region        = var.zone.gcp_region
  network       = var.zone.globals.vpc_id

  stack_type                 = "IPV4_IPV6"
  ipv6_access_type           = "EXTERNAL"
  private_ip_google_access   = true
  private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"

  secondary_ip_range {
    range_name    = "tenant"
    ip_cidr_range = var.node_cidr
  }

  labels = {
    service_attachment_cidr = replace(replace(var.service_attachment_cidr, ".", "_"), "/", "-")
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "itcp_proxy_fe_subnetwork" {
  name          = "${local.zone_name}-subnet-itcp-proxy-fe"
  ip_cidr_range = var.lb_cidr
  region        = var.zone.gcp_region
  network       = var.zone.globals.vpc_id

  private_ip_google_access   = true
  private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_internal_traffic" {
  #checkov:skip=CKV2_GCP_12:Communication internally on the private network is allowed
  name          = "${local.zone_name}-firewall-allow-internal-traffic"
  network       = var.zone.globals.vpc_name
  priority      = 2000
  source_ranges = [var.host_cidr, var.node_cidr, var.lb_cidr, var.service_attachment_cidr, var.zone.proxy_only_cidr]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_internal_ipv6_traffic" {
  #checkov:skip=CKV2_GCP_12:Communication internally on the private network is allowed
  name          = "${local.zone_name}-firewall-allow-internal-ipv6-traffic"
  network       = var.zone.globals.vpc_name
  priority      = 2100
  source_ranges = [cidrsubnet(google_compute_subnetwork.subnetwork.external_ipv6_prefix, 0, 0)] # cidrsubnet() to normalize to avoid diff

  allow {
    protocol = "all"
  }
}
