# Networking resources for Vespa zone

locals {
  # x.y.0.0/16    VPC
  # x.y.0.0/22    tenant hosts
  # x.y.92.0/22   internal TCP proxies (ServiceConnect), in a separate declaration
  # x.y.96.0/20   proxy-use-only (ServiceConnect), in a separate declaration
  # x.y.128.0/17  tenants. Each host gets /96, first for the host and remainder for nodes
  hosts_cidr_block         = cidrsubnet(var.zone_ipv4_cidr, 6, 0)
  tenants_cidr_block       = cidrsubnet(var.zone_ipv4_cidr, 1, 1)
  proxy_cidr_block         = cidrsubnet(var.zone_ipv4_cidr, 4, 6)
  internal_tcp_proxy_block = cidrsubnet(var.zone_ipv4_cidr, 6, 23)
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "${local.zone_name}-subnet-tenant-host"
  ip_cidr_range = local.hosts_cidr_block
  region        = var.zone.gcp_region
  network       = var.zone.globals.vpc_id

  stack_type                 = "IPV4_IPV6"
  ipv6_access_type           = "EXTERNAL"
  private_ip_google_access   = true
  private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"

  secondary_ip_range {
    range_name    = "tenant"
    ip_cidr_range = local.tenants_cidr_block
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "tcp_proxy_only_subnetwork" {
  # checkov:skip=CKV_GCP_74:TCP proxy subnetwork is used for ServiceConnect
  # checkov:skip=CKV_GCP_76:TCP proxy subnetwork is used for ServiceConnect
  name          = "${local.zone_name}-subnet-tcp-proxy-only"
  ip_cidr_range = local.proxy_cidr_block
  region        = var.zone.gcp_region
  network       = var.zone.globals.vpc_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_subnetwork" "itcp_proxy_fe_subnetwork" {
  name          = "${local.zone_name}-subnet-itcp-proxy-fe"
  ip_cidr_range = local.internal_tcp_proxy_block
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
  source_ranges = [var.zone_ipv4_cidr]

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
