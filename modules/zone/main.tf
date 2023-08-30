terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

locals {
  network_name = "${var.zone.environment}-${var.zone.gcp_zone}"

  # x.y.0.0/16    VPC
  # x.y.0.0/22    tenant hosts
  # x.y.92.0/22   internal TCP proxies (ServiceConnect), in a separate declaration
  # x.y.96.0/20   proxy-use-only (ServiceConnect), in a separate declaration
  # x.y.128.0/17  tenants. Each host gets /96, first for the host and remainder for nodes
  hosts_cidr_block   = cidrsubnet(var.zone_ipv4_cidr, 6, 0)
  tenants_cidr_block = cidrsubnet(var.zone_ipv4_cidr, 1, 1)
  proxy_cidr_block   = cidrsubnet(var.zone_ipv4_cidr, 4, 6)
  internal_tcp_proxy_block = cidrsubnet(var.zone_ipv4_cidr, 6, 23)
}

module "archive" {
  source = "../archive"
  zone   = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                    = local.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "${local.network_name}-subnet-tenant-host"
  ip_cidr_range = local.hosts_cidr_block
  region        = var.zone.gcp_region
  network       = google_compute_network.vpc_network.id

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
  name          = "${local.network_name}-subnet-tcp-proxy-only"
  ip_cidr_range = local.proxy_cidr_block
  region        = var.zone.gcp_region
  network       = google_compute_network.vpc_network.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_subnetwork" "itcp_proxy_fe_subnetwork" {
  name          = "${local.network_name}-subnet-itcp-proxy-fe"
  ip_cidr_range = local.internal_tcp_proxy_block
  region        = var.zone.gcp_region
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = true
  private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_region_health_check" "tenant_health_check" {
  name   = "${local.network_name}-healthcheck-tenant"
  region = var.zone.gcp_region

  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 2

  https_health_check {
    port         = 4443
    request_path = "/status.html"
    proxy_header = "PROXY_V1"
  }
}

resource "google_compute_address" "router_eip" {
  name         = "${local.network_name}-eip-nat-gw"
  region       = var.zone.gcp_region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM" # Must use premium for router
}

resource "google_compute_router" "nat" {
  name    = "${local.network_name}-router-nat-gw"
  region  = var.zone.gcp_region
  network = google_compute_network.vpc_network.id
}

resource "google_compute_router_nat" "nat" {
  name                               = google_compute_router.nat.name
  router                             = google_compute_router.nat.name
  region                             = google_compute_router.nat.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ips                            = [google_compute_address.router_eip.id]
}

resource "google_compute_firewall" "allow_internal_traffic" {
  #checkov:skip=CKV2_GCP_12:Communication internally on the private network is allowed
  name          = "${local.network_name}-firewall-allow-internal-traffic"
  network       = google_compute_network.vpc_network.name
  priority      = 2000
  source_ranges = [var.zone_ipv4_cidr]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_internal_ipv6_traffic" {
  #checkov:skip=CKV2_GCP_12:Communication internally on the private network is allowed
  name          = "${local.network_name}-firewall-allow-internal-ipv6-traffic"
  network       = google_compute_network.vpc_network.name
  priority      = 2100
  source_ranges = [cidrsubnet(google_compute_subnetwork.subnetwork.external_ipv6_prefix, 0, 0)] # cidrsubnet() to normalize to avoid diff

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name          = "${local.network_name}-firewall-allow-ssh"
  network       = google_compute_network.vpc_network.name
  priority      = 10000
  source_ranges = ["35.235.240.0/20"] # https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule

  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

# allow access from health check ranges
resource "google_compute_firewall" "allow_health_check" {
  name          = "${local.network_name}-firewall-allow-health-check"
  network       = google_compute_network.vpc_network.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # https://cloud.google.com/load-balancing/docs/https#health-checks

  allow {
    protocol = "tcp"
    ports    = [4443]
  }
}

resource "google_kms_key_ring" "disk" {
  name     = "${local.network_name}-vespa-cloud-disk-key"
  location = var.zone.gcp_region
}

#checkov:skip=CKV_GCP_82: No prevent_destroy to allow tenants run terraform destroy
resource "google_kms_crypto_key" "disk" {
  name            = "disk-encryption"
  key_ring        = google_kms_key_ring.disk.id
  rotation_period = "7776000s" // 90 days
}
